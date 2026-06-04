import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const DEFAULT_VIRTUES = [
  { name: 'Kindness', description: 'Showing compassion and generosity to others without expecting anything in return.', icon: '💖' },
  { name: 'Discipline', description: 'The ability to control impulses and stay committed to goals and responsibilities.', icon: '🎯' },
  { name: 'Honesty', description: 'Being truthful and transparent in words and actions.', icon: '💎' },
  { name: 'Courage', description: 'Facing fears and challenges with strength and determination.', icon: '🦁' },
  { name: 'Wisdom', description: 'Making thoughtful decisions based on knowledge, experience, and reflection.', icon: '🦉' },
  { name: 'Gratitude', description: 'Recognizing and appreciating the blessings and good things in life.', icon: '🙏' },
  { name: 'Patience', description: 'Remaining calm and composed when facing delays, difficulties, or suffering.', icon: '🌿' },
  { name: 'Responsibility', description: 'Taking ownership of your actions and their consequences.', icon: '🛡️' },
  { name: 'Humility', description: 'Having a modest view of your importance and being open to learning.', icon: '🌊' },
  { name: 'Compassion', description: 'Feeling empathy for others and taking action to help alleviate their suffering.', icon: '🤲' },
  { name: 'Perseverance', description: 'Continuing to pursue goals despite obstacles, failures, or discouragement.', icon: '⛰️' },
  { name: 'Generosity', description: 'Freely giving time, resources, or effort to others.', icon: '🎁' },
];

async function main() {
  console.log('🌱 Seeding database...');

  for (const virtue of DEFAULT_VIRTUES) {
    await prisma.virtue.upsert({
      where: { name: virtue.name },
      update: {},
      create: virtue,
    });
  }

  console.log(`✅ Seeded ${DEFAULT_VIRTUES.length} virtues`);
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
