import { Job } from "bull";
import { EmailJobData, PasswordResetEmailJob, WelcomeEmailJob } from "../types/emailJobs";
import Mail from "../utils/emailUtils";
import config from "../config/config";
import winston from "winston";

// Configure logger for queue operations
const logger = winston.createLogger({
	level: "info",
	format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
	transports: [new winston.transports.File({ filename: "logs/mail-queue.log" }), new winston.transports.Console()],
});

export const processMailJob = async (job: Job<EmailJobData>) => {
	const { type, data } = job.data;

	logger.info(`Processing email job: ${type}`, { jobId: job.id, email: data.email });

	try {
		switch (type) {
			case "PASSWORD_RESET":
				await sendPasswordResetEmail(data);
				break;
			case "WELCOME":
				await sendWelcomeEmail(data);
				break;
			default:
				throw new Error(`Unknown email job type: ${type}`);
		}

		logger.info(`Email job completed successfully: ${type}`, { jobId: job.id });
	} catch (error) {
		logger.error(`Email job failed: ${type}`, {
			jobId: job.id,
			error: error instanceof Error ? error.message : "Unknown error",
			attempt: job.attemptsMade + 1,
		});
		throw error;
	}
};

const sendPasswordResetEmail = async (data: PasswordResetEmailJob["data"]) => {
	const templateData = {
		name: data.name,
		resetUrl: data.resetUrl,
		supportEmail: "support@stakcast.com",
		companyName: "StakCast",
	};

	await Mail.sendHtmlEmail(data.email, "Reset Your Password - StakCast", "passwordReset", templateData);
};

const sendWelcomeEmail = async (data: WelcomeEmailJob["data"]) => {
	const templateData = {
		name: data.name,
		companyName: "StakCast",
	};

	await Mail.sendHtmlEmail(data.email, "Welcome to StakCast!", "welcome", templateData);
};
