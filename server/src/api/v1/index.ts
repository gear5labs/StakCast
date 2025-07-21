import { Router } from "express";
import authRouter from "./Auth/auth.routes";
import userRouter from "./User/user.routes";
import marketRouter from "./Market/buyshares.routes";
const v1: Router = Router();

v1.use("/auth", authRouter);
v1.use("/user", userRouter);
v1.use("/market", marketRouter);

export default v1;
