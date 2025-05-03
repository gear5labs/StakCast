import winston from "winston";

const { combine, timestamp, printf, errors } = winston.format;

const customFormat = printf(({ level, message, timestamp, stack }) => {
	return `${timestamp} [${level}]: ${stack || message}`;
});

const logger = winston.createLogger({
	level: "info",
	format: combine(timestamp(), errors({ stack: true }), customFormat),
	transports: [
		new winston.transports.File({ filename: "logs/error.log", level: "error" }),
		new winston.transports.File({ filename: "logs/req.log", level: "info" }),
		new winston.transports.File({ filename: "logs/combined.log" }),
		new winston.transports.Console(),
	],
});

export default logger;
