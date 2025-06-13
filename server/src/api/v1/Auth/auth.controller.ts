import { Request, Response } from "express";
import { injectable } from "tsyringe";
import AuthService from "./auth.service";
import { Helper } from "../../../utils/Helper"
import { ApplicationError } from "../../../utils/errorHandler";


@injectable()
export default class AuthController {
	constructor(private authService: AuthService) {}

	async register(req: Request, res: Response) {
		try {
			const { email, password, firstName, lastName } = req.body;
			const result = await this.authService.register(email, password, firstName, lastName);
			return Helper.successResponse(res, "User registered successfully", result);
		} catch (error) {
			const err = error as ApplicationError;
      		return Helper.errorResponse(res, err.message, err.statusCode || 400, err.details);
		}
	}

	async login(req: Request, res: Response) {
		try {
			const { email, password } = req.body;
			const result = await this.authService.login(email, password);
			return Helper.successResponse(res, "Login successful", result);
		} catch (error) {
			const err = error as ApplicationError;
      		return Helper.errorResponse(res, err.message, err.statusCode || 401, err.details);
		}
	}

	async logout(req: Request, res: Response) {
		try {
			const userId = req.user?.id;
			if (!userId) {
				return res.status(401).json({ error: "Unauthorized" });
			}
			await this.authService.logout(userId);
			res.json({ message: "Logged out successfully" });
		} catch (error) {
			const err = error as ApplicationError;
      		return Helper.errorResponse(res, err.message, err.statusCode || 400, err.details);
		}
	}

	async refreshToken(req: Request, res: Response) {
		try {
			const { refreshToken } = req.body;
			if (!refreshToken) {
				return res.status(400).json({ error: "Refresh token is required" });
			}
			const result = await this.authService.refreshToken(refreshToken);
			res.json(result);
		} catch (error) {
			const err = error as ApplicationError;
      		return Helper.errorResponse(res, err.message, err.statusCode || 401, err.details);
		}
	}

	async changePassword(req: Request, res: Response) {
		try {

			const { currentPassword, newPassword } = req.body;
			const userId = req.user.id;
			await this.authService.changePassword(userId, currentPassword, newPassword);
			res.json({ message: "Password changed successfully" });
		} catch (error) {
			const err = error as ApplicationError;
      		return Helper.errorResponse(res, err.message, err.statusCode || 400, err.details);
		}
    }

	async forgotPassword(req: Request, res: Response) {
		try {
			const { email } = req.body;
			await this.authService.sendPasswordResetMail(email);
			res.json({ message: "Password reset link sent" });
		} catch (error) {
			const err = error as ApplicationError;
      		return Helper.errorResponse(res, err.message, err.statusCode || 400, err.details);
		}
	}

	async resetPassword(req: Request, res: Response) {
		try {
			const { token, newPassword } = req.body;
			await this.authService.resetPassword(token, newPassword);
			res.json({ message: "Password has been reset" });
		} catch (error) {
			const err = error as ApplicationError;
      		return Helper.errorResponse(res, err.message, err.statusCode || 400, err.details);
		}
	}

  async googleSignIn(req: Request, res: Response) {
		try {
			const { idToken } = req.body;
			const result = await this.authService.googleSignIn(idToken);
			res.json(result);
		} catch (error) {
			const err = error as ApplicationError;
      		return Helper.errorResponse(res, err.message, err.statusCode || 401, err.details);
		}
  }
}
