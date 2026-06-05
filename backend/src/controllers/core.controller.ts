import { Request, Response, NextFunction } from 'express';
import { actionService, virtueService, intentionService, blessingService, reflectionService, storyService, mentorService, userService, obligationService, wishService } from '../services/core.service.js';

// ─── Actions ────────────────────────────────────────────────────────────────────

export const actionController = {
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await actionService.create(req.user!.userId, req.body.actionText, req.body.actionType, req.body.source);
      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const result = await actionService.getByUser(req.user!.userId, page, limit);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async getOne(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await actionService.getById(req.user!.userId, req.params.id as string);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async remove(req: Request, res: Response, next: NextFunction) {
    try {
      await actionService.delete(req.user!.userId, req.params.id as string);
      res.json({ success: true, message: 'Deleted' });
    } catch (err) { next(err); }
  },
};

// ─── Virtues ────────────────────────────────────────────────────────────────────

export const virtueController = {
  async getAll(_req: Request, res: Response, next: NextFunction) {
    try {
      const virtues = await virtueService.getAllVirtues();
      res.json({ success: true, data: virtues });
    } catch (err) { next(err); }
  },

  async getUserVirtues(req: Request, res: Response, next: NextFunction) {
    try {
      const virtues = await virtueService.getUserVirtues(req.user!.userId);
      res.json({ success: true, data: virtues });
    } catch (err) { next(err); }
  },

  async getHistory(req: Request, res: Response, next: NextFunction) {
    try {
      const days = parseInt(req.query.days as string) || 30;
      const history = await virtueService.getVirtueHistory(req.user!.userId, req.params.id as string, days);
      res.json({ success: true, data: history });
    } catch (err) { next(err); }
  },

  async getReadiness(req: Request, res: Response, next: NextFunction) {
    try {
      const readiness = await virtueService.getReadinessScore(req.user!.userId);
      res.json({ success: true, data: readiness });
    } catch (err) { next(err); }
  },
};

// ─── Intentions ─────────────────────────────────────────────────────────────────

export const intentionController = {
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await intentionService.create(req.user!.userId, req.body.title, req.body.description);
      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await intentionService.getByUser(req.user!.userId, req.query.status as string);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async update(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await intentionService.update(req.user!.userId, req.params.id as string, req.body);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async remove(req: Request, res: Response, next: NextFunction) {
    try {
      await intentionService.delete(req.user!.userId, req.params.id as string);
      res.json({ success: true, message: 'Deleted' });
    } catch (err) { next(err); }
  },
};

// ─── Blessings ──────────────────────────────────────────────────────────────────

export const blessingController = {
  async create(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await blessingService.create(req.user!.userId, req.body);
      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const result = await blessingService.getByUser(req.user!.userId, page);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async remove(req: Request, res: Response, next: NextFunction) {
    try {
      await blessingService.delete(req.user!.userId, req.params.id as string);
      res.json({ success: true, message: 'Deleted' });
    } catch (err) { next(err); }
  },
};

// ─── Reflections ────────────────────────────────────────────────────────────────

export const reflectionController = {
  async generate(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await reflectionService.generate(req.user!.userId, req.body.reflectionType, req.body.userNotes);
      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await reflectionService.getByUser(req.user!.userId, req.query.type as string);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },
};

// ─── Story ──────────────────────────────────────────────────────────────────────

export const storyController = {
  async generate(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await storyService.generateChapter(req.user!.userId);
      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await storyService.getByUser(req.user!.userId);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },
};

// ─── Mentor ─────────────────────────────────────────────────────────────────────

export const mentorController = {
  async chat(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await mentorService.chat(req.user!.userId, req.body.message);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async getHistory(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await mentorService.getHistory(req.user!.userId);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async clearHistory(req: Request, res: Response, next: NextFunction) {
    try {
      await mentorService.clearHistory(req.user!.userId);
      res.json({ success: true, message: 'History cleared' });
    } catch (err) { next(err); }
  },
};

// ─── User / Dashboard ──────────────────────────────────────────────────────────

export const userController = {
  async getProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await userService.getProfile(req.user!.userId);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async updateProfile(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await userService.updateProfile(req.user!.userId, req.body);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async getStats(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await userService.getStats(req.user!.userId);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async getDashboard(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await userService.getDashboard(req.user!.userId);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },
};

// ─── Obligations ────────────────────────────────────────────────────────────────

export const obligationController = {
  async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await obligationService.getByUser(req.user!.userId);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async resolve(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await obligationService.resolve(req.user!.userId, req.params.id as string);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },
};

// ─── Wishes ─────────────────────────────────────────────────────────────────────

export const wishController = {
  async getAll(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await wishService.getByUser(req.user!.userId);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async create(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await wishService.create(req.user!.userId, req.body.title, req.body.description);
      res.status(201).json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async grant(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await wishService.grant(req.user!.userId, req.params.id as string);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },

  async remove(req: Request, res: Response, next: NextFunction) {
    try {
      const result = await wishService.remove(req.user!.userId, req.params.id as string);
      res.json({ success: true, data: result });
    } catch (err) { next(err); }
  },
};

