import { Request, Response } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { ApiError } from "../utils/apiError";
import { prisma } from "../config/prisma";
import * as geminiService from "../services/gemini.service";

export const chat = asyncHandler(async (req: Request, res: Response) => {
  if (!req.user?.userId) throw ApiError.unauthorized();
  const { query, context, sessionId } = req.body;

  let session;
  if (sessionId) {
    session = await prisma.chatSession.findUnique({ where: { id: sessionId } });
  }

  const history = session ? (session.messages as Array<{ role: string; content: string }>) : [];
  const result = await geminiService.getCoachAdvice(context || "", query, history);

  // Extract text from Gemini response
  const responseData = result as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
  const responseText = responseData.candidates?.[0]?.content?.parts?.[0]?.text || "";

  // Update or create session
  const updatedMessages = [...history, { role: "user", content: query }, { role: "assistant", content: responseText }];

  if (session) {
    await prisma.chatSession.update({
      where: { id: session.id },
      data: { messages: updatedMessages },
    });
  } else {
    session = await prisma.chatSession.create({
      data: { userId: req.user.userId, messages: updatedMessages },
    });
  }

  res.json({ success: true, data: { response: responseText, sessionId: session.id } });
});
