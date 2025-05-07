import { Request, Response, NextFunction } from "express";
import { container } from "tsyringe";
import AuthService from "../api/v1/Auth/AuthService";
import HttpStatusCodes from "../constants/HttpStatusCodes";
import { ApplicationError } from "../utils/errorHandler";

export const silentAuthMiddleware = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const accessToken = req.headers.authorization?.split(" ")[1];
		const refreshToken = req.headers["refresh-token"] as string;
		const fingerprint = req.headers["x-device-fingerprint"] as string;

		if (!accessToken) {
			throw new ApplicationError("No access token provided", HttpStatusCodes.UNAUTHORIZED);
		}

		const authService = container.resolve(AuthService);

		try {
			await authService.verifyAccessToken(accessToken);
			next();
		} catch (error: any) {
			if (error.name === "TokenExpiredError") {
				if (!refreshToken || !fingerprint) {
					throw new ApplicationError("Token expired and missing refresh credentials", HttpStatusCodes.UNAUTHORIZED);
				}

				await authService.validateTokenDevice(refreshToken, fingerprint);
				next();
			} else {
				throw new ApplicationError("Invalid token", HttpStatusCodes.UNAUTHORIZED);
			}
		}
	} catch (error) {
		next(error);
	}
};
