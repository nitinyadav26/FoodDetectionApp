declare namespace Express {
  interface Request {
    user?: {
      uid: string;
      email?: string;
      userId?: string;
    };
  }
}
