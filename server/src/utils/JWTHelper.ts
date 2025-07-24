import jwt, { JwtPayload } from "jsonwebtoken";
import { ApplicationError } from "./errorHandler";
import HttpStatusCodes from "../constants/HttpStatusCodes";
import config from "../config/config";

const accessTokenSecret = config.JWT.accessToken.secret;
const refreshTokenSecret = config.JWT.refreshToken.secret;

class JwtHelper {
	public constructor() {}

	public generateAccessToken(userId: string) {
		return jwt.sign({ userId }, accessTokenSecret, {
			expiresIn: config.JWT.accessToken.exp as '15m',
		});
	}

	public generateRefreshToken(userId: string) {
		return jwt.sign({ userId }, refreshTokenSecret, {
			expiresIn: config.JWT.refreshToken.exp as '15m',
		});
	}

	public verifyAccessToken(token: string) {
		try {
			return jwt.verify(token, accessTokenSecret);
		} catch (error) {
			throw new ApplicationError("Invalid Token", HttpStatusCodes.UNAUTHORIZED);
		}
	}

	public verifyRefreshToken(token: string) {
		try {
			const decoded = jwt.verify(token, refreshTokenSecret) as JwtPayload;

			if (!decoded.userId) {
				throw new ApplicationError("Invalid Token", HttpStatusCodes.UNAUTHORIZED);
			}

			return decoded.userId;
		} catch (error) {
			throw new ApplicationError("Invalid Token", HttpStatusCodes.UNAUTHORIZED);
		}
	}
}

export default JwtHelper;
