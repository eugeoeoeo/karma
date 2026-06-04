import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { prisma } from '../utils/prisma.js';
import { ConflictError, UnauthorizedError } from '../utils/errors.js';
import type { AuthPayload } from '../middlewares/auth.js';

const SALT_ROUNDS = 12;

function generateAccessToken(payload: AuthPayload): string {
  return jwt.sign(payload, process.env.JWT_SECRET!, { expiresIn: (process.env.JWT_EXPIRES_IN || '15m') as any });
}

function generateRefreshToken(): string {
  return uuidv4();
}

export const authService = {
  async register(email: string, username: string, password: string) {
    const existing = await prisma.user.findFirst({ where: { OR: [{ email }, { username }] } });
    if (existing) {
      throw new ConflictError(existing.email === email ? 'Email already registered' : 'Username already taken');
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    const user = await prisma.user.create({ data: { email, username, passwordHash } });

    const accessToken = generateAccessToken({ userId: user.id, email: user.email });
    const refreshToken = generateRefreshToken();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

    await prisma.refreshToken.create({ data: { token: refreshToken, userId: user.id, expiresAt } });

    // Initialize user virtues
    const virtues = await prisma.virtue.findMany();
    await prisma.userVirtue.createMany({
      data: virtues.map((v) => ({ userId: user.id, virtueId: v.id })),
    });

    return {
      user: { id: user.id, email: user.email, username: user.username, avatarStage: user.avatarStage },
      accessToken,
      refreshToken,
    };
  },

  async login(email: string, password: string) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) throw new UnauthorizedError('Invalid credentials');

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) throw new UnauthorizedError('Invalid credentials');

    const accessToken = generateAccessToken({ userId: user.id, email: user.email });
    const refreshToken = generateRefreshToken();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await prisma.refreshToken.create({ data: { token: refreshToken, userId: user.id, expiresAt } });

    return {
      user: { id: user.id, email: user.email, username: user.username, avatarStage: user.avatarStage },
      accessToken,
      refreshToken,
    };
  },

  async refresh(token: string) {
    const stored = await prisma.refreshToken.findUnique({ where: { token }, include: { user: true } });
    if (!stored || stored.expiresAt < new Date()) {
      if (stored) await prisma.refreshToken.delete({ where: { id: stored.id } });
      throw new UnauthorizedError('Invalid or expired refresh token');
    }

    // Rotate refresh token
    await prisma.refreshToken.delete({ where: { id: stored.id } });
    const newRefreshToken = generateRefreshToken();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await prisma.refreshToken.create({ data: { token: newRefreshToken, userId: stored.userId, expiresAt } });

    const accessToken = generateAccessToken({ userId: stored.userId, email: stored.user.email });
    return { accessToken, refreshToken: newRefreshToken };
  },

  async logout(token: string) {
    await prisma.refreshToken.deleteMany({ where: { token } });
  },
};
