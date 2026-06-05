import { Router } from 'express';
import { authController } from '../controllers/auth.controller.js';
import { actionController, virtueController, intentionController, blessingController, reflectionController, storyController, mentorController, userController, obligationController, wishController } from '../controllers/core.controller.js';
import { aiService } from '../services/ai.service.js';
import { authenticateToken } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { registerSchema, loginSchema, refreshSchema, actionLogSchema, intentionSchema, intentionUpdateSchema, blessingSchema, reflectionSchema, mentorChatSchema, updateProfileSchema, wishSchema } from '../schemas/index.js';

const router = Router();

// ─── Auth (Public) ──────────────────────────────────────────────────────────────
router.post('/auth/register', validate(registerSchema), authController.register);
router.post('/auth/login', validate(loginSchema), authController.login);
router.post('/auth/refresh', validate(refreshSchema), authController.refresh);
router.post('/auth/logout', authController.logout);

// AI Status
router.get('/ai/status', (_req, res) => {
  res.json({ success: true, data: aiService.getStatus() });
});
router.post('/ai/status/reset', (_req, res) => {
  aiService.resetStatus();
  res.json({ success: true, data: aiService.getStatus() });
});

// ─── Protected Routes ──────────────────────────────────────────────────────────
router.use(authenticateToken);

// Dashboard
router.get('/dashboard', userController.getDashboard);

// User
router.get('/user/profile', userController.getProfile);
router.patch('/user/profile', validate(updateProfileSchema), userController.updateProfile);
router.get('/user/stats', userController.getStats);

// Actions
router.post('/actions', validate(actionLogSchema), actionController.create);
router.get('/actions', actionController.getAll);
router.get('/actions/:id', actionController.getOne);
router.delete('/actions/:id', actionController.remove);

// Virtues
router.get('/virtues', virtueController.getAll);
router.get('/virtues/user', virtueController.getUserVirtues);
router.get('/virtues/readiness', virtueController.getReadiness);
router.get('/virtues/:id/history', virtueController.getHistory);

// Intentions
router.post('/intentions', validate(intentionSchema), intentionController.create);
router.get('/intentions', intentionController.getAll);
router.patch('/intentions/:id', validate(intentionUpdateSchema), intentionController.update);
router.delete('/intentions/:id', intentionController.remove);

// Blessings
router.post('/blessings', validate(blessingSchema), blessingController.create);
router.get('/blessings', blessingController.getAll);
router.delete('/blessings/:id', blessingController.remove);

// Reflections
router.post('/reflections', validate(reflectionSchema), reflectionController.generate);
router.get('/reflections', reflectionController.getAll);

// Story
router.post('/story/generate', storyController.generate);
router.get('/story', storyController.getAll);

// Mentor
router.post('/mentor/chat', validate(mentorChatSchema), mentorController.chat);
router.get('/mentor/history', mentorController.getHistory);
router.delete('/mentor/history', mentorController.clearHistory);

// Obligations
router.get('/obligations', obligationController.getAll);
router.patch('/obligations/:id/resolve', obligationController.resolve);

// Wishes
router.get('/wishes', wishController.getAll);
router.post('/wishes', validate(wishSchema), wishController.create);
router.post('/wishes/:id/grant', wishController.grant);
router.delete('/wishes/:id', wishController.remove);

export default router;
