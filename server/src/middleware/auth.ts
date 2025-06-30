import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { container } from "tsyringe";
import AuthService from "../api/v1/Auth/auth.service";
import UserRepository from "../api/v1/User/user.repository";

const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";

declare global {
	namespace Express {
		interface Request {
			user?: {
				id: string;
				isAdmin?: boolean;
			};
		}
	}
}

export const authenticateToken = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const authHeader = req.headers.authorization;
		const token = authHeader?.split(" ")[1];

		if (!token) {
			return res.status(401).json({ error: "No token provided" });
		}

		try {
			const decoded = jwt.verify(token, JWT_SECRET) as { userId: string; id?: string };
			const authService = container.resolve(AuthService);
			const user = await authService.validateToken(token);
			const userRepository = container.resolve(UserRepository);
			const dbUser = await userRepository.findById(user.id);
			req.user = { id: user.id, isAdmin: dbUser?.isAdmin ?? false };
			next();
		} catch (error) {
			return res.status(401).json({ error: "Invalid token" });
		}
	} catch (error) {
		return res.status(401).json({ error: "Authentication failed" });
	}
};

export const requireAdmin = (req: Request, res: Response, next: NextFunction) => {
	if (!req.user?.isAdmin) {
		return res.status(403).json({ error: "Admin access required" });
	}
	next();
};
