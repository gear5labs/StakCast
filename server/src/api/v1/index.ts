import { Router } from "express";
import authRouter from "./Auth/auth.routes";
import userRouter from "./User/user.routes";
import adminRouter from "./Admin/admin.routes";
const v1: Router = Router();

v1.use("/auth", authRouter);
v1.use("/user", userRouter);
v1.use("/admin", adminRouter);

export default v1;
