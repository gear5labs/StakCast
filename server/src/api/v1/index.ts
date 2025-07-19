import { Router } from "express";
import authRouter from "./Auth/auth.routes";
import userRouter from "./User/user.routes";
const v1: Router = Router();

v1.use("/auth", authRouter);
v1.use("/user", userRouter);

export default v1;
