import { prisma } from '../utils/prisma.js';
import { aiService } from './ai.service.js';
import { NotFoundError } from '../utils/errors.js';

export const actionService = {
  async create(userId: string, actionText: string, actionType: 'GOOD' | 'NEGATIVE', source: 'TEXT' | 'VOICE') {
    // AI analysis
    const analysis = await aiService.analyzeAction(actionText, actionType);

    // Create action log
    const action = await prisma.actionLog.create({
      data: {
        userId,
        actionText,
        actionType,
        source,
        impact: analysis.totalImpact,
        confidence: analysis.confidence,
        aiAnalysis: analysis as any,
      },
    });

    // Link virtues and update scores
    for (const v of analysis.virtues) {
      const virtue = await prisma.virtue.findUnique({ where: { name: v.name } });
      if (!virtue) continue;

      await prisma.actionVirtue.create({
        data: { actionLogId: action.id, virtueId: virtue.id, impact: v.impact },
      });

      // Update user virtue score (never goes below 0)
      const userVirtue = await prisma.userVirtue.findUnique({
        where: { userId_virtueId: { userId, virtueId: virtue.id } },
      });

      if (userVirtue) {
        const newScore = Math.max(0, userVirtue.score + v.impact);
        const newLevel = Math.floor(newScore / 100) + 1;

        await prisma.userVirtue.update({
          where: { id: userVirtue.id },
          data: { score: newScore, level: newLevel },
        });
      }
    }

    // Update avatar stage
    await updateAvatarStage(userId);

    return { ...action, analysis };
  },

  async getByUser(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [actions, total] = await Promise.all([
      prisma.actionLog.findMany({
        where: { userId },
        include: { actionVirtues: { include: { virtue: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.actionLog.count({ where: { userId } }),
    ]);

    return { actions, total, page, pages: Math.ceil(total / limit) };
  },

  async getById(userId: string, id: string) {
    const action = await prisma.actionLog.findFirst({
      where: { id, userId },
      include: { actionVirtues: { include: { virtue: true } } },
    });
    if (!action) throw new NotFoundError('Action');
    return action;
  },

  async delete(userId: string, id: string) {
    const action = await prisma.actionLog.findFirst({ where: { id, userId } });
    if (!action) throw new NotFoundError('Action');
    await prisma.actionLog.delete({ where: { id } });
  },
};

export const virtueService = {
  async getAllVirtues() {
    return prisma.virtue.findMany({ orderBy: { name: 'asc' } });
  },

  async getUserVirtues(userId: string) {
    return prisma.userVirtue.findMany({
      where: { userId },
      include: { virtue: true },
      orderBy: { score: 'desc' },
    });
  },

  async getVirtueHistory(userId: string, virtueId: string, days = 30) {
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const actions = await prisma.actionVirtue.findMany({
      where: { virtueId, actionLog: { userId, createdAt: { gte: since } } },
      include: { actionLog: { select: { createdAt: true, actionType: true } } },
      orderBy: { actionLog: { createdAt: 'asc' } },
    });
    return actions;
  },

  async getReadinessScore(userId: string) {
    const userVirtues = await prisma.userVirtue.findMany({ where: { userId } });
    const totalScore = userVirtues.reduce((sum, uv) => sum + uv.score, 0);
    const avgLevel = userVirtues.reduce((sum, uv) => sum + uv.level, 0) / (userVirtues.length || 1);

    const reflections = await prisma.reflection.count({ where: { userId } });
    const completedIntentions = await prisma.intention.count({ where: { userId, status: 'COMPLETED' } });
    const totalActions = await prisma.actionLog.count({ where: { userId } });

    // Weighted readiness calculation
    const readiness = Math.round(
      totalScore * 0.4 + avgLevel * 50 * 0.2 + reflections * 30 * 0.2 + completedIntentions * 100 * 0.1 + totalActions * 5 * 0.1
    );

    return { readiness, totalScore, avgLevel: Math.round(avgLevel * 10) / 10, reflections, completedIntentions, totalActions };
  },
};

export const intentionService = {
  async create(userId: string, title: string, description?: string) {
    return prisma.intention.create({ data: { userId, title, description } });
  },

  async getByUser(userId: string, status?: string) {
    const where: any = { userId };
    if (status) where.status = status;
    return prisma.intention.findMany({ where, orderBy: { createdAt: 'desc' } });
  },

  async update(userId: string, id: string, data: { title?: string; description?: string; status?: string; progress?: number }) {
    const intention = await prisma.intention.findFirst({ where: { id, userId } });
    if (!intention) throw new NotFoundError('Intention');

    const updateData: any = { ...data };
    if (data.status === 'COMPLETED') updateData.completedAt = new Date();

    return prisma.intention.update({ where: { id }, data: updateData });
  },

  async delete(userId: string, id: string) {
    const intention = await prisma.intention.findFirst({ where: { id, userId } });
    if (!intention) throw new NotFoundError('Intention');
    await prisma.intention.delete({ where: { id } });
  },
};

export const blessingService = {
  async create(userId: string, data: { title: string; description?: string; blessingType: 'EXPECTED' | 'UNEXPECTED'; reflection?: string }) {
    const analysis = await aiService.analyzeBlessing(data.title, data.description);

    const blessing = await prisma.blessing.create({
      data: {
        userId,
        title: data.title,
        description: data.description,
        blessingType: data.blessingType,
        significanceScore: analysis.significance,
        reflection: data.reflection || analysis.reflection,
        aiAnalysis: { ...analysis } as any,
      },
    });

    // Check gratitude obligation
    const readiness = await virtueService.getReadinessScore(userId);
    if (analysis.significance > readiness.readiness) {
      await prisma.gratitudeObligation.create({
        data: {
          userId,
          blessingId: blessing.id,
          obligationScore: analysis.significance - readiness.readiness,
        },
      });
    }

    return { ...blessing, analysis };
  },

  async getByUser(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [blessings, total] = await Promise.all([
      prisma.blessing.findMany({
        where: { userId },
        include: { gratitudeObligations: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.blessing.count({ where: { userId } }),
    ]);
    return { blessings, total, page, pages: Math.ceil(total / limit) };
  },

  async delete(userId: string, id: string) {
    const blessing = await prisma.blessing.findFirst({ where: { id, userId } });
    if (!blessing) throw new NotFoundError('Blessing');
    await prisma.blessing.delete({ where: { id } });
  },
};

export const reflectionService = {
  async generate(userId: string, type: 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY', userNotes?: string) {
    const now = new Date();
    const periodMap = { DAILY: 1, WEEKLY: 7, MONTHLY: 30, YEARLY: 365 };
    const days = periodMap[type];
    const periodStart = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);

    const [actions, blessings, intentions] = await Promise.all([
      prisma.actionLog.findMany({ where: { userId, createdAt: { gte: periodStart } }, orderBy: { createdAt: 'desc' } }),
      prisma.blessing.findMany({ where: { userId, createdAt: { gte: periodStart } }, orderBy: { createdAt: 'desc' } }),
      prisma.intention.findMany({ where: { userId, status: 'ACTIVE' } }),
    ]);

    const result = await aiService.generateReflection(actions, blessings, intentions, type);
    const generatedText = typeof result === 'string' ? result : result.text;

    const reflection = await prisma.reflection.create({
      data: { userId, reflectionType: type, generatedText, userNotes, periodStart, periodEnd: now },
    });

    return { ...reflection, isAI: typeof result === 'string' ? true : result.isAI };
  },

  async getByUser(userId: string, type?: string) {
    const where: any = { userId };
    if (type) where.reflectionType = type;
    return prisma.reflection.findMany({ where, orderBy: { createdAt: 'desc' }, take: 50 });
  },
};

export const storyService = {
  async generateChapter(userId: string) {
    const lastChapter = await prisma.storyChapter.findFirst({
      where: { userId },
      orderBy: { chapterNumber: 'desc' },
    });

    const chapterNumber = (lastChapter?.chapterNumber || 0) + 1;
    const periodStart = lastChapter?.periodEnd || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const periodEnd = new Date();

    const [actions, reflections, blessings] = await Promise.all([
      prisma.actionLog.findMany({ where: { userId, createdAt: { gte: periodStart, lte: periodEnd } } }),
      prisma.reflection.findMany({ where: { userId, createdAt: { gte: periodStart, lte: periodEnd } } }),
      prisma.blessing.findMany({ where: { userId, createdAt: { gte: periodStart, lte: periodEnd } } }),
    ]);

    const { title, story } = await aiService.generateStoryChapter(actions, reflections, blessings, chapterNumber);

    return prisma.storyChapter.create({
      data: { userId, chapterNumber, chapterTitle: title, generatedStory: story, periodStart, periodEnd },
    });
  },

  async getByUser(userId: string) {
    return prisma.storyChapter.findMany({ where: { userId }, orderBy: { chapterNumber: 'asc' } });
  },
};

export const mentorService = {
  async chat(userId: string, message: string) {
    // Save user message
    await prisma.mentorMessage.create({ data: { userId, role: 'USER', content: message } });

    // Get context
    const [userVirtues, recentMessages] = await Promise.all([
      prisma.userVirtue.findMany({ where: { userId }, include: { virtue: true } }),
      prisma.mentorMessage.findMany({ where: { userId }, orderBy: { createdAt: 'desc' }, take: 20 }),
    ]);

    const context = {
      virtues: userVirtues.map((uv) => ({ name: uv.virtue.name, score: uv.score, level: uv.level })),
    };

    const chatHistory = recentMessages.reverse().map((m) => ({ role: m.role.toLowerCase(), content: m.content }));
    const result = await aiService.mentorChat(chatHistory, context);

    // Save assistant reply
    await prisma.mentorMessage.create({ data: { userId, role: 'ASSISTANT', content: result.reply } });

    return { reply: result.reply, isAI: result.isAI };
  },

  async getHistory(userId: string) {
    return prisma.mentorMessage.findMany({ where: { userId }, orderBy: { createdAt: 'asc' }, take: 100 });
  },

  async clearHistory(userId: string) {
    await prisma.mentorMessage.deleteMany({ where: { userId } });
  },
};

export const userService = {
  async getProfile(userId: string) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundError('User');
    const { passwordHash, ...profile } = user;
    return profile;
  },

  async updateProfile(userId: string, data: { username?: string; profilePicture?: string }) {
    const user = await prisma.user.update({ where: { id: userId }, data });
    const { passwordHash, ...profile } = user;
    return profile;
  },

  async getStats(userId: string) {
    const [totalActions, goodActions, negativeActions, totalBlessings, totalReflections, activeIntentions, completedIntentions, readiness, totalWishes, grantedWishes] = await Promise.all([
      prisma.actionLog.count({ where: { userId } }),
      prisma.actionLog.count({ where: { userId, actionType: 'GOOD' } }),
      prisma.actionLog.count({ where: { userId, actionType: 'NEGATIVE' } }),
      prisma.blessing.count({ where: { userId } }),
      prisma.reflection.count({ where: { userId } }),
      prisma.intention.count({ where: { userId, status: 'ACTIVE' } }),
      prisma.intention.count({ where: { userId, status: 'COMPLETED' } }),
      virtueService.getReadinessScore(userId),
      prisma.wish.count({ where: { userId } }),
      prisma.wish.count({ where: { userId, status: 'GRANTED' } }),
    ]);

    return { totalActions, goodActions, negativeActions, totalBlessings, totalReflections, activeIntentions, completedIntentions, readiness, totalWishes, grantedWishes };
  },

  async getDashboard(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [virtues, recentActions, activeIntentions, recentBlessings, todayReflection, stats, obligations, wishes] = await Promise.all([
      virtueService.getUserVirtues(userId),
      prisma.actionLog.findMany({ where: { userId }, orderBy: { createdAt: 'desc' }, take: 5, include: { actionVirtues: { include: { virtue: true } } } }),
      prisma.intention.findMany({ where: { userId, status: 'ACTIVE' }, take: 5 }),
      prisma.blessing.findMany({ where: { userId }, orderBy: { createdAt: 'desc' }, take: 3 }),
      prisma.reflection.findFirst({ where: { userId, reflectionType: 'DAILY', createdAt: { gte: today } } }),
      userService.getStats(userId),
      prisma.gratitudeObligation.findMany({ where: { userId, resolved: false }, include: { blessing: true }, take: 3 }),
      prisma.wish.findMany({ where: { userId }, orderBy: { createdAt: 'desc' }, take: 5 }),
    ]);

    const user = await userService.getProfile(userId);

    return { user, virtues, recentActions, activeIntentions, recentBlessings, todayReflection, stats, obligations, wishes };
  },
};

export const wishService = {
  async getByUser(userId: string) {
    return prisma.wish.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  },

  async create(userId: string, title: string, description?: string) {
    const analysis = await aiService.analyzeWish(title, description);

    return prisma.wish.create({
      data: {
        userId,
        title,
        description,
        virtueName: analysis.virtueName,
        requiredLevel: analysis.requiredLevel,
        cost: analysis.cost,
        status: 'PENDING',
      },
    });
  },

  async grant(userId: string, wishId: string) {
    const wish = await prisma.wish.findFirst({ where: { id: wishId, userId } });
    if (!wish) throw new NotFoundError('Wish');
    if (wish.status === 'GRANTED') {
      throw new Error('Wish already granted');
    }

    const virtue = await prisma.virtue.findUnique({ where: { name: wish.virtueName } });
    if (!virtue) throw new NotFoundError('Virtue');

    const userVirtue = await prisma.userVirtue.findUnique({
      where: { userId_virtueId: { userId, virtueId: virtue.id } },
    });
    if (!userVirtue) throw new Error('User virtue profile not found');

    if (userVirtue.level < wish.requiredLevel) {
      throw new Error(`You are not worthy yet. Required ${wish.virtueName} Level ${wish.requiredLevel}, current is Level ${userVirtue.level}.`);
    }

    const newScore = Math.max(0, userVirtue.score - wish.cost);
    const newLevel = Math.floor(newScore / 100) + 1;

    await prisma.$transaction([
      prisma.userVirtue.update({
        where: { id: userVirtue.id },
        data: { score: newScore, level: newLevel },
      }),
      prisma.wish.update({
        where: { id: wishId },
        data: { status: 'GRANTED' },
      }),
    ]);

    await updateAvatarStage(userId);

    return { success: true, newScore, newLevel };
  },

  async remove(userId: string, wishId: string) {
    const wish = await prisma.wish.findFirst({ where: { id: wishId, userId } });
    if (!wish) throw new NotFoundError('Wish');
    await prisma.wish.delete({ where: { id: wishId } });
    return { success: true };
  },
};

export const obligationService = {
  async getByUser(userId: string) {
    return prisma.gratitudeObligation.findMany({
      where: { userId },
      include: { blessing: true },
      orderBy: { createdAt: 'desc' },
    });
  },

  async resolve(userId: string, id: string) {
    const obligation = await prisma.gratitudeObligation.findFirst({ where: { id, userId } });
    if (!obligation) throw new NotFoundError('Obligation');
    return prisma.gratitudeObligation.update({ where: { id }, data: { resolved: true, resolvedAt: new Date() } });
  },
};

// ─── Helpers ────────────────────────────────────────────────────────────────────

async function updateAvatarStage(userId: string) {
  const userVirtues = await prisma.userVirtue.findMany({ where: { userId } });
  const totalScore = userVirtues.reduce((sum, uv) => sum + uv.score, 0);

  let stage = 1;
  if (totalScore >= 5000) stage = 5;
  else if (totalScore >= 2000) stage = 4;
  else if (totalScore >= 800) stage = 3;
  else if (totalScore >= 200) stage = 2;

  await prisma.user.update({ where: { id: userId }, data: { avatarStage: stage } });
}
