import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
dotenv.config();

const key = process.env.GEMINI_API_KEY;
console.log('Using Key:', key ? key.substring(0, 10) + '...' : 'NONE');

if (!key) {
  console.error('No GEMINI_API_KEY found in .env');
  process.exit(1);
}

const genAI = new GoogleGenerativeAI(key);
const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash-lite' });

try {
  const result = await model.generateContent('Hello! Tell me in 5 words that you are online.');
  console.log('SUCCESS:', result.response.text());
} catch (err) {
  console.error('ERROR:', err);
}
