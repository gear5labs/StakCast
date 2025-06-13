import express, { NextFunction } from "express";
import logger from "../config/logger";

export class ApplicationError extends Error {
	statusCode: number;
	message: string;
	details?: any;

	constructor(message: string, statusCode: number, details?: any) {
		super(message);
		this.statusCode = statusCode;
		this.message = message;
	}
}


export class NotFoundError extends ApplicationError {
	constructor(message = "Resource Not Found") {
		super(message, 404);
	}
}

export class ValidationError extends ApplicationError {
	constructor(message = "Validation Failed", details?: any) {
		super(message, 400, details);
	}
}

export class InternalServerError extends ApplicationError {
	constructor(message = "Internal server error") {
    	super(message, 500);
  }
}

export class DatabaseError extends ApplicationError {
  constructor(message = "Database error", details?: any) {
    super(message, 500, details);
  }
}


const RouteErrorHandler =
	(fn: (req: express.Request, res: express.Response, next: NextFunction) => Promise<any>) =>
	(req: express.Request, res: express.Response, next: NextFunction) =>
		Promise.resolve(fn(req, res, next)).catch(error => next(error));

export async function ErrorHandler(err: any, req: express.Request, res: express.Response, next: express.NextFunction) {
	const duplicateKeyCodes = ["23505", "11000"];

	if (duplicateKeyCodes.includes(err?.code)) {
    	err = new DatabaseError("Duplicate key violation", err.detail || err.keyValue || err.message);
  	}

  	const statusCode = err?.statusCode || 500;
  	const message = err?.message || "Internal server error";
  	const details = err?.details || null;


	logger.error(`Error occurred: ${err.message} at ${req.method} ${req.url}`, {

		statusCode,
    	method: req.method,
    	url: req.url,
    	ip: req.ip,
    	stack: err.stack,
	});

	return res.status(err?.statusCode || 500).json({
		status: "error",
    	message,
    	details,
	});
}

export default RouteErrorHandler;
