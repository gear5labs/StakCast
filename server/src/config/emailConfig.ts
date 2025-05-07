import nodemailer from "nodemailer";
import config from "./config";
const { email } = config;

const transporter = nodemailer.createTransport({
	host: email.SMTP_HOST,
	port: 587,
	secure: false,
	auth: {
		user: email.user,
		pass: email.password,
	},
});

export default transporter;
