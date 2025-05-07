import express, { NextFunction } from "express";
import logger from "../config/logger";

export class ApplicationError extends Error {
	statusCode: number;
	message: string;

	constructor(message: string, statusCode: number) {
		super(message);
		this.statusCode = statusCode;
		this.message = message;
	}
}

const RouteErrorHandler =
	(fn: (req: express.Request, res: express.Response, next: NextFunction) => Promise<any>) =>
	(req: express.Request, res: express.Response, next: NextFunction) =>
		Promise.resolve(fn(req, res, next)).catch(error => next(error));

export async function ErrorHandler(err: any, req: express.Request, res: express.Response, next: express.NextFunction) {
	logger.error(`Error occurred: ${err.message} at ${req.method} ${req.url}`, {
		statusCode: err.statusCode || 500,
		method: req.method,
		url: req.url,
		ip: req.ip,
	});

	return res.status(err?.statusCode || 500).json({
		success: false,
		status: err?.statusCode || 500,
		msg: `${err?.message}` || "Internal server error",
		error: err,
	});
}

export default RouteErrorHandler;
