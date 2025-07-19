import { Request, Response, NextFunction } from "express";
import { container } from "tsyringe";
import AuthService from "../api/v1/Auth/auth.service";
import HttpStatusCodes from "../constants/HttpStatusCodes";
import { ApplicationError } from "../utils/errorHandler";

declare global {
	namespace Express {
		interface Request {
			user?: {
				id: string;
			};
		}
	}
}

export const silentAuthMiddleware = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const authHeader = req.headers.authorization;
		const token = authHeader?.split(" ")[1];

		if (!token) {
			return next();
		}

		try {
			const authService = container.resolve(AuthService);
			const user = await authService.validateToken(token);
			req.user = { id: user.id };
		} catch (error) {
			// Silently fail - don't set user but continue
		}
		next();
	} catch (error) {
		next();
	}
};
