import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email('Invalid email'),
  username: z.string().min(3, 'Username must be at least 3 characters').max(30).regex(/^[a-zA-Z0-9_]+$/, 'Only letters, numbers, and underscores'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

export const loginSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(1, 'Password required'),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token required'),
});

export const actionLogSchema = z.object({
  actionText: z.string().min(1, 'Action text required').max(2000),
  actionType: z.enum(['GOOD', 'NEGATIVE']).default('GOOD'),
  source: z.enum(['TEXT', 'VOICE']).default('TEXT'),
});

export const intentionSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
});

export const intentionUpdateSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).optional(),
  status: z.enum(['ACTIVE', 'COMPLETED', 'PAUSED', 'ABANDONED']).optional(),
  progress: z.number().min(0).max(100).optional(),
});

export const blessingSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  blessingType: z.enum(['EXPECTED', 'UNEXPECTED']).default('UNEXPECTED'),
  reflection: z.string().max(5000).optional(),
});

export const reflectionSchema = z.object({
  reflectionType: z.enum(['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY']).default('DAILY'),
  userNotes: z.string().max(5000).optional(),
});

export const mentorChatSchema = z.object({
  message: z.string().min(1).max(5000),
});

export const updateProfileSchema = z.object({
  username: z.string().min(3).max(30).regex(/^[a-zA-Z0-9_]+$/).optional(),
  profilePicture: z.string().url().optional(),
});

export const wishSchema = z.object({
  title: z.string().min(1, 'Wish title required').max(200),
  description: z.string().max(2000).optional(),
});

