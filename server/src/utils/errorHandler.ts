import { Request, Response, NextFunction } from "express";
import logger from "../config/logger";

export class ApplicationError extends Error {
	statusCode: number;
	message: string;

	constructor(message: string, statusCode: number) {
		super(message);
		this.statusCode = statusCode;
		this.message = message;
	}
}

export const asyncHandler =
	(fn: (req: Request, res: Response, next: NextFunction) => Promise<any>) =>
	(req: Request, res: Response, next: NextFunction) =>
		Promise.resolve(fn(req, res, next)).catch(next);

export async function ErrorHandler(err: any, req: Request, res: Response, next: NextFunction) {
	if (err instanceof ApplicationError) {
		logger.error(`Application Error: ${err.message}`, { statusCode: err.statusCode });
		return res.status(err.statusCode).json({ error: err.message });
	}

	logger.error(`Unhandled Error: ${err.message}`, { stack: err.stack });
	return res.status(500).json({ error: "Internal Server Error" });
}

export default ErrorHandler;
