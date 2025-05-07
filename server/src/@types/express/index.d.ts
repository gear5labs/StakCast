import { IUser } from "../../models/User.model";
import * as express from "express";
declare global {
	declare namespace Express {
		export interface Request {
			user?: IUser;
		}
	}
}

export {};
