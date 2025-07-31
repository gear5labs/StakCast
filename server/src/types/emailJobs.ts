export interface PasswordResetEmailJob {
	type: "PASSWORD_RESET";
	data: {
		email: string;
		name: string;
		resetToken: string;
		resetUrl: string;
	};
}

export interface WelcomeEmailJob {
	type: "WELCOME";
	data: {
		email: string;
		name: string;
	};
}

export type EmailJobData = PasswordResetEmailJob | WelcomeEmailJob;
