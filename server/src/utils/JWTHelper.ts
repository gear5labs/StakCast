import jwt, { JwtPayload } from "jsonwebtoken";
import { ApplicationError } from "./errorHandler";
import HttpStatusCodes from "../constants/HttpStatusCodes";
import config from "../config/config";

const accessTokenSecret = config.JWT.accessToken.secret;
const refreshTokenSecret = config.JWT.refreshToken.secret;
export type TimeUnit = "s" | "m" | "h" | "d" | "w" | "y";
export type DurationString = `${number}${TimeUnit}`;
class JwtHelper {
	public constructor() {}

	public generateAccessToken(userId: string) {
		return jwt.sign({ userId }, accessTokenSecret, {
			expiresIn: config.JWT.accessToken.exp as DurationString,
		});
	}

	public generateRefreshToken(userId: string) {
		return jwt.sign({ userId }, refreshTokenSecret as string, {
			expiresIn: config.JWT.refreshToken.exp as number | DurationString | undefined,
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