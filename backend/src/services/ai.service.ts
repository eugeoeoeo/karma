import { GoogleGenerativeAI } from '@google/generative-ai';
import { logger } from '../utils/logger.js';

// ─── Gemini Setup ───────────────────────────────────────────────────────────────

const genAI = process.env.GEMINI_API_KEY
  ? new GoogleGenerativeAI(process.env.GEMINI_API_KEY)
  : null;

// Use the cheapest model for all operations
const getModel = () => genAI?.getGenerativeModel({ model: 'gemini-2.0-flash-lite' }) ?? null;

// ─── AI Status Tracking ─────────────────────────────────────────────────────────

let aiAvailable = !!process.env.GEMINI_API_KEY;
let aiErrorCount = 0;
const AI_ERROR_THRESHOLD = 5; // After 5 consecutive errors, mark AI as unavailable

function markAIError() {
  aiErrorCount++;
  if (aiErrorCount >= AI_ERROR_THRESHOLD) {
    aiAvailable = false;
    logger.warn('AI marked as unavailable after repeated failures');
  }
}

function markAISuccess() {
  aiErrorCount = 0;
  aiAvailable = true;
}

// ─── Types ──────────────────────────────────────────────────────────────────────

export interface ActionAnalysis {
  virtues: { name: string; impact: number }[];
  totalImpact: number;
  confidence: number;
  insight: string;
  isAI: boolean;
}

export interface BlessingAnalysis {
  category: 'Minor' | 'Moderate' | 'Major' | 'Extraordinary';
  significance: number;
  reflection: string;
  isAI: boolean;
}

// ─── Keyword-Based Local Analysis (Primary - Zero tokens) ───────────────────────

const VIRTUE_KEYWORDS: Record<string, string[]> = {
  Kindness: ['help', 'helped', 'helping', 'kind', 'gave', 'shared', 'donate', 'care', 'cared', 'support', 'supported', 'comfort', 'encouraged', 'volunteer'],
  Discipline: ['studied', 'study', 'exercise', 'exercised', 'woke', 'early', 'routine', 'practice', 'practiced', 'train', 'trained', 'focus', 'focused', 'consistent', 'organized'],
  Honesty: ['truth', 'honest', 'admitted', 'confess', 'transparent', 'sincere', 'truthful', 'genuine', 'authentic', 'integrity'],
  Courage: ['brave', 'faced', 'confront', 'confronted', 'stood', 'defend', 'defended', 'risk', 'risked', 'spoke up', 'overcome', 'overcame'],
  Wisdom: ['learn', 'learned', 'taught', 'teach', 'read', 'reflect', 'reflected', 'think', 'understood', 'insight', 'mentor', 'advice'],
  Gratitude: ['thank', 'thanked', 'grateful', 'appreciate', 'appreciated', 'blessed', 'thankful', 'gratitude'],
  Patience: ['wait', 'waited', 'patient', 'calm', 'composed', 'endure', 'endured', 'tolerate', 'tolerated', 'steady', 'persisted'],
  Responsibility: ['clean', 'cleaned', 'organize', 'fix', 'fixed', 'manage', 'managed', 'complete', 'completed', 'finish', 'finished', 'own', 'owned', 'accountable'],
  Humility: ['apologize', 'apologized', 'sorry', 'humble', 'accept', 'accepted', 'listen', 'listened', 'acknowledge', 'admit'],
  Compassion: ['comfort', 'comforted', 'empathize', 'felt for', 'understand', 'console', 'consoled', 'sympathy', 'caring'],
  Perseverance: ['persist', 'persisted', 'continue', 'continued', 'kept going', 'tried again', 'never gave up', 'determined', 'resilient', 'push', 'pushed'],
  Generosity: ['gave', 'give', 'shared', 'share', 'donate', 'donated', 'offer', 'offered', 'treat', 'treated', 'gift'],
};

const INSIGHT_TEMPLATES_GOOD = [
  (virtues: string) => `Your actions reflect ${virtues}. These small moments of goodness accumulate into lasting character.`,
  (virtues: string) => `By practicing ${virtues}, you strengthen the foundation of who you are. Keep going.`,
  (virtues: string) => `This shows genuine ${virtues}. Remember, consistency in virtue is what creates transformation.`,
  (virtues: string) => `Beautiful demonstration of ${virtues}. Every intentional act of good shapes your story.`,
];

const INSIGHT_TEMPLATES_NEGATIVE = [
  (virtues: string) => `This is a growth opportunity for ${virtues}. Awareness is the first step toward change.`,
  (virtues: string) => `Recognizing this moment shows self-awareness. Focus on building ${virtues} going forward.`,
  (virtues: string) => `Everyone stumbles. What matters is your willingness to reflect and grow in ${virtues}.`,
];

function localActionAnalysis(text: string, type: string): ActionAnalysis {
  const isGood = type === 'GOOD';
  const lower = text.toLowerCase();
  const detected: { name: string; impact: number }[] = [];

  for (const [virtue, keywords] of Object.entries(VIRTUE_KEYWORDS)) {
    let matchScore = 0;
    for (const kw of keywords) {
      if (lower.includes(kw)) matchScore++;
    }
    if (matchScore > 0) {
      const impact = isGood ? Math.min(matchScore * 4 + 2, 18) : Math.min(matchScore * -2 - 1, -1);
      detected.push({ name: virtue, impact });
    }
  }

  // Fallback if no keywords matched
  if (detected.length === 0) {
    detected.push({ name: isGood ? 'Kindness' : 'Discipline', impact: isGood ? 5 : -3 });
  }

  const totalImpact = detected.reduce((sum, v) => sum + v.impact, 0);
  const virtueNames = detected.map(v => v.name).join(' and ');
  const templates = isGood ? INSIGHT_TEMPLATES_GOOD : INSIGHT_TEMPLATES_NEGATIVE;
  const insight = templates[Math.floor(Math.random() * templates.length)](virtueNames);

  return { virtues: detected, totalImpact, confidence: 0.65 + detected.length * 0.05, insight, isAI: false };
}

function localBlessingAnalysis(title: string, description?: string): BlessingAnalysis {
  const text = `${title} ${description || ''}`.toLowerCase();
  const words = text.split(/\s+/).length;

  // Simple heuristic: longer + certain keywords = higher significance
  const majorKeywords = ['promotion', 'job', 'graduate', 'birth', 'married', 'house', 'heal', 'recovered', 'scholarship', 'award', 'accepted', 'passed', 'exam'];
  const moderateKeywords = ['friend', 'opportunity', 'raise', 'improve', 'success', 'achieve', 'milestone'];

  let significance = words * 50;
  for (const kw of majorKeywords) if (text.includes(kw)) significance += 800;
  for (const kw of moderateKeywords) if (text.includes(kw)) significance += 300;
  significance = Math.min(significance, 5000);

  const category = significance < 500 ? 'Minor' : significance < 1500 ? 'Moderate' : significance < 3000 ? 'Major' : 'Extraordinary';

  const reflections = [
    'Take a moment to sit with this blessing. How might you honor it through your future actions?',
    'This is a reminder of the good that flows through life. Consider how you can share this fortune with others.',
    'Reflect on the journey that led to this moment. Every step of growth prepared you for it.',
  ];

  return { category, significance, reflection: reflections[Math.floor(Math.random() * reflections.length)], isAI: false };
}

function localReflection(actions: any[], blessings: any[]): string {
  const good = actions.filter((a: any) => a.actionType === 'GOOD').length;
  const neg = actions.filter((a: any) => a.actionType === 'NEGATIVE').length;
  const total = actions.length;
  const bCount = blessings.length;

  let reflection = `## Your Reflection\n\n`;

  if (total === 0) {
    reflection += `You haven't logged any actions during this period. That's okay — today is a fresh start. Consider logging even one small positive action.\n\n`;
  } else {
    reflection += `During this period, you logged **${good} positive action${good !== 1 ? 's' : ''}** and reflected on **${neg} area${neg !== 1 ? 's' : ''} for growth**.\n\n`;
    if (good > neg * 2) {
      reflection += `You're building strong momentum! Your consistent positive actions are shaping your character in meaningful ways.\n\n`;
    } else if (good > neg) {
      reflection += `You're on the right path. Every positive action strengthens your virtues, and acknowledging areas for growth shows wisdom.\n\n`;
    } else {
      reflection += `Growth often comes from our most challenging moments. The fact that you're reflecting shows genuine self-awareness and courage.\n\n`;
    }
  }

  if (bCount > 0) {
    reflection += `You recognized **${bCount} blessing${bCount !== 1 ? 's' : ''}** — this practice of gratitude is itself a virtue.\n\n`;
  }

  reflection += `> *Remember: growth is not about perfection. It's about the sincere intention to become a little better each day.*\n\n`;
  reflection += `*— This reflection was generated locally. For deeper AI-powered insights, ensure your AI connection is active.*`;

  return reflection;
}

// ─── Gemini AI Calls (Enhanced - Minimal tokens) ────────────────────────────────

async function geminiAnalyzeAction(text: string, type: string): Promise<ActionAnalysis> {
  const model = getModel();
  if (!model || !aiAvailable) return localActionAnalysis(text, type);

  try {
    // Ultra-compact prompt to minimize tokens
    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: `Analyze this ${type} action for virtues. Pick from: Kindness,Discipline,Honesty,Courage,Wisdom,Gratitude,Patience,Responsibility,Humility,Compassion,Perseverance,Generosity. Reply ONLY valid JSON: {"v":[{"n":"Name","i":number}],"t":number,"c":0.9,"s":"1 sentence insight"} where i=impact(1-18 good,-1 to-12 neg),t=total,c=confidence,s=insight. No divine claims. Action: "${text}"` }] }],
      generationConfig: { maxOutputTokens: 150, temperature: 0.2 },
    });

    const raw = result.response.text().replace(/```json\n?|\n?```/g, '').trim();
    const parsed = JSON.parse(raw);
    markAISuccess();

    return {
      virtues: (parsed.v || []).map((v: any) => ({ name: v.n, impact: v.i })),
      totalImpact: parsed.t || 0,
      confidence: parsed.c || 0.85,
      insight: parsed.s || '',
      isAI: true,
    };
  } catch (err) {
    logger.error(err, 'Gemini action analysis failed');
    markAIError();
    return localActionAnalysis(text, type);
  }
}

async function geminiAnalyzeBlessing(title: string, description?: string): Promise<BlessingAnalysis> {
  const model = getModel();
  if (!model || !aiAvailable) return localBlessingAnalysis(title, description);

  try {
    const input = description ? `${title}: ${description}` : title;
    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: `Rate this blessing. Reply ONLY JSON: {"c":"Minor|Moderate|Major|Extraordinary","s":number(100-5000),"r":"1 sentence reflection"} No divine claims. Blessing: "${input}"` }] }],
      generationConfig: { maxOutputTokens: 80, temperature: 0.2 },
    });

    const raw = result.response.text().replace(/```json\n?|\n?```/g, '').trim();
    const parsed = JSON.parse(raw);
    markAISuccess();

    return { category: parsed.c, significance: parsed.s, reflection: parsed.r, isAI: true };
  } catch (err) {
    logger.error(err, 'Gemini blessing analysis failed');
    markAIError();
    return localBlessingAnalysis(title, description);
  }
}

async function geminiReflection(actions: any[], blessings: any[], intentions: any[], type: string): Promise<{ text: string; isAI: boolean }> {
  const model = getModel();
  if (!model || !aiAvailable) return { text: localReflection(actions, blessings), isAI: false };

  try {
    // Send minimal data to reduce input tokens
    const goodCount = actions.filter((a: any) => a.actionType === 'GOOD').length;
    const negCount = actions.filter((a: any) => a.actionType === 'NEGATIVE').length;
    const topActions = actions.slice(0, 5).map((a: any) => a.actionText.slice(0, 50));
    const topBlessings = blessings.slice(0, 3).map((b: any) => b.title);
    const topIntentions = intentions.slice(0, 3).map((i: any) => i.title);

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: `Write a ${type.toLowerCase()} reflection (150 words max, markdown). ${goodCount} good acts, ${negCount} growth areas. Acts: ${topActions.join(';')}. Blessings: ${topBlessings.join(';')}. Goals: ${topIntentions.join(';')}. Be warm, encouraging. No divine claims.` }] }],
      generationConfig: { maxOutputTokens: 250, temperature: 0.7 },
    });

    markAISuccess();
    return { text: result.response.text(), isAI: true };
  } catch (err) {
    logger.error(err, 'Gemini reflection failed');
    markAIError();
    return { text: localReflection(actions, blessings), isAI: false };
  }
}

async function geminiStoryChapter(actions: any[], reflections: any[], blessings: any[], chapterNumber: number): Promise<{ title: string; story: string; isAI: boolean }> {
  const model = getModel();
  const fallback = {
    title: `Chapter ${chapterNumber}: A Season of Growth`,
    story: `This chapter captures your journey through ${actions.length} recorded actions and ${blessings.length} recognized blessings. Each step forward, no matter how small, writes the next line of your story.\n\n*This chapter was generated locally. Connect AI for richer narratives.*`,
    isAI: false,
  };

  if (!model || !aiAvailable) return fallback;

  try {
    const topActions = actions.slice(0, 8).map((a: any) => `${a.actionType === 'GOOD' ? '+' : '-'}${a.actionText.slice(0, 40)}`);
    const topBlessings = blessings.slice(0, 4).map((b: any) => b.title);

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: `Write life chapter ${chapterNumber} (200 words max). JSON: {"t":"Chapter N: Title","s":"markdown story"}. Acts: ${topActions.join(';')}. Blessings: ${topBlessings.join(';')}. Poetic but authentic. No divine claims.` }] }],
      generationConfig: { maxOutputTokens: 350, temperature: 0.8 },
    });

    const raw = result.response.text().replace(/```json\n?|\n?```/g, '').trim();
    const parsed = JSON.parse(raw);
    markAISuccess();

    return { title: parsed.t || fallback.title, story: parsed.s || fallback.story, isAI: true };
  } catch (err) {
    logger.error(err, 'Gemini story failed');
    markAIError();
    return fallback;
  }
}

async function geminiMentorChat(messages: { role: string; content: string }[], userContext: any): Promise<{ reply: string; isAI: boolean }> {
  const model = getModel();
  const fallback = {
    reply: "I'm currently operating in offline mode. While I can't provide AI-powered guidance right now, here are some suggestions:\n\n• Reflect on one virtue you want to strengthen today\n• Log a small positive action — even the smallest counts\n• Take a moment to recognize a blessing in your life\n\n*AI mentor is temporarily unavailable. This is a pre-written suggestion.*",
    isAI: false,
  };

  if (!model || !aiAvailable) return fallback;

  try {
    // Only send last 6 messages + minimal context to save tokens
    const recentMsgs = messages.slice(-6).map(m => `${m.role}: ${m.content.slice(0, 200)}`).join('\n');
    const virtuesSummary = (userContext.virtues || []).slice(0, 5).map((v: any) => `${v.name}:L${v.level}`).join(',');

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: `You are Karma Mentor, a warm growth guide. User virtues: ${virtuesSummary}. Be concise (100 words max). No divine claims. Only guide, never modify scores.\n\nConversation:\n${recentMsgs}` }] }],
      generationConfig: { maxOutputTokens: 180, temperature: 0.7 },
    });

    markAISuccess();
    return { reply: result.response.text(), isAI: true };
  } catch (err) {
    logger.error(err, 'Gemini mentor failed');
    markAIError();
    return fallback;
  }
}

// ─── Public API ─────────────────────────────────────────────────────────────────

export const aiService = {
  analyzeAction: geminiAnalyzeAction,
  analyzeBlessing: geminiAnalyzeBlessing,

  async generateReflection(actions: any[], blessings: any[], intentions: any[], type: string) {
    return geminiReflection(actions, blessings, intentions, type);
  },

  async generateStoryChapter(actions: any[], reflections: any[], blessings: any[], chapterNumber: number) {
    return geminiStoryChapter(actions, reflections, blessings, chapterNumber);
  },

  async mentorChat(messages: { role: string; content: string }[], userContext: any) {
    return geminiMentorChat(messages, userContext);
  },

  getStatus() {
    return {
      available: aiAvailable,
      configured: !!process.env.GEMINI_API_KEY,
      errorCount: aiErrorCount,
      model: 'gemini-2.0-flash-lite',
    };
  },

  resetStatus() {
    aiErrorCount = 0;
    aiAvailable = !!process.env.GEMINI_API_KEY;
  },
};
