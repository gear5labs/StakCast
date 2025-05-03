import { Request, Response } from "express";
import { autoInjectable } from "tsyringe";
import AuthService from "./AuthService";
import UserService from "../User/User.service";
import HttpStatusCodes from "../../../constants/HttpStatusCodes";
import { ApplicationError } from "../../../utils/errorHandler";
import Helper from "../../../utils/Helper";
const { SuccessResponse } = Helper;

@autoInjectable()
class AuthController {
	private authService: AuthService;

	constructor(authService: AuthService) {
		this.authService = authService;
	}

	
	public async register(req: Request, res: Response): Promise<Response> {
		const { email, password } = req.body;
		const deviceInfo = {
			fingerprint: req.headers["x-device-fingerprint"] as string,
			userAgent: req.headers["user-agent"] || "",
			ip: req.ip || "",
		};
		const { accessToken, refreshToken, user } = await this.authService.registerUser(email, password, deviceInfo);
		return res
			.status(HttpStatusCodes.OK)
			.json(SuccessResponse("User registered successfully", { accessToken, refreshToken, user }));
	}


	public async login(req: Request, res: Response): Promise<Response> {
		const { identifier, password } = req.body;
		const deviceInfo = {
			fingerprint: req.headers["x-device-fingerprint"] as string,
			userAgent: req.headers["user-agent"] || "",
			ip: req.ip || "",
		};

		const { accessToken, refreshToken, user } = await this.authService.loginUser(identifier, password, deviceInfo);

		return res.status(HttpStatusCodes.OK).json(
			SuccessResponse("successful login", {
				name: user.firstName + user.lastName,
				tokens: {
					accessToken,
					refreshToken,
				},
			})
		);
	}

	public async silentRefresh(req: Request, res: Response): Promise<Response> {
		const refreshToken = req.headers["refresh-token"] as string;
		const fingerprint = req.headers["x-device-fingerprint"] as string;

		if (!refreshToken || !fingerprint) {
			throw new ApplicationError("Missing required headers", HttpStatusCodes.BAD_REQUEST);
		}

		const tokenStatus = await this.authService.validateTokenDevice(refreshToken, fingerprint);

		return res.status(HttpStatusCodes.OK).json(
			SuccessResponse("Token still valid", {
				lastUsed: tokenStatus?.lastUsed,
				useCount: tokenStatus?.useCount,
			})
		);
	}


}

export default AuthController;
