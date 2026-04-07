import { prisma } from "../config/prisma";
import * as gemini from "../config/gemini";

export async function generateQuiz(topic: string) {
  return gemini.generateQuiz(topic);
}

export async function submitQuizScore(userId: string, topic: string, score: number, total: number) {
  const xpEarned = Math.round((score / total) * 20);

  const quizScore = await prisma.quizScore.create({
    data: { userId, topic, score, total, xpEarned },
  });

  if (xpEarned > 0) {
    await prisma.profile.update({
      where: { userId },
      data: { xp: { increment: xpEarned } },
    });
  }

  return { ...quizScore, xpEarned };
}
