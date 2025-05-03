import User from "../api/v1/User/User.model";

class Helper {
	private static count = 0;

	private constructor() {}

	public static async generateUsername(firstName: string, lastName: string, organization: string): Promise<string> {
		let generatedUsername = `${firstName}.${lastName}${this.count ? this.count : ""}@${organization}`;

		let isUserNameExists = !!(await User.findOne({
			username: generatedUsername,
		}));

		if (isUserNameExists) {
			this.count += 1;
			return this.generateUsername(firstName, lastName, organization);
		}

		return generatedUsername;
	}

	public static SuccessResponse<T>(body: string, data: T) {
		return {
			success: true,
			message: body,
			data,
		};
	}
}

export default Helper;
