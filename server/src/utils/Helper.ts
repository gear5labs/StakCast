import User from "../api/v1/User/user.entity";
import { Response } from "express"

class Helper {
	private static count = 0;

	private constructor() {}

	// public static async generateUsername(firstName: string, lastName: string, organization: string): Promise<string> {
	// 	let generatedUsername = `${firstName}.${lastName}${this.count ? this.count : ""}@${organization}`;

	// 	let isUserNameExists = !!(await User.findOne({
	// 		username: generatedUsername,
	// 	}));

	// 	if (isUserNameExists) {
	// 		this.count += 1;
	// 		return this.generateUsername(firstName, lastName, organization);
	// 	}

	// 	return generatedUsername;
	// }

	public static successResponse<T>(res: Response, message: string, data: T, statusCode = 200) {
		return res.status(statusCode).json({
      		status: "success",
      		message,
      		data,
    	});
	}

	public static errorResponse(res: Response, message: string, statusCode = 500, details: any = null) {
		return res.status(statusCode).json({
			status: "error",
			message,
			details,
		});
  	}
}

export default Helper;
