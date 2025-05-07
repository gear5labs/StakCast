import transporter from "../config/emailConfig";
import HttpStatusCodes from "../constants/HttpStatusCodes";
import { ApplicationError } from "./errorHandler";
import path from "path";
import ejs from "ejs";
class Mail {
	private constructor() {}
	public static generateOtp(length: number) {
		return Math.random()
			.toString()
			.substring(2, length + 2);
	}
	public static async sendEmail(to: string, subject: string, text: string): Promise<void> {
		const mailOptions = {
			from: process.env.EMAIL_USER,
			to,
			subject,
			text,
		};

		try {
			await transporter.sendMail(mailOptions);
		} catch (error) {
			console.error("Error sending email:", error);
			throw new ApplicationError("Failed to send email", HttpStatusCodes.BAD_REQUEST);
		}
	}

	public static async sendHtmlEmail(to: string, subject: string, templateName: string, data: object): Promise<void> {
		try {
			const templatePath = path.join(__dirname, "../views", `${templateName}.ejs`);

			const htmlContent = await ejs.renderFile(templatePath, data);

			const mailOptions = {
				from: "noreply@sandlabs.com",
				to,
				subject,
				html: htmlContent,
			};

			await transporter.sendMail(mailOptions);
		} catch (error) {
			console.error("Error sending HTML email:", error);
			throw new ApplicationError("Failed to send email", HttpStatusCodes.BAD_REQUEST);
		}
	}
}
export default Mail;
