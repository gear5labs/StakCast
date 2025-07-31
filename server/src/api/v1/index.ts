import { Router } from "express";
import authRouter from "./Auth/auth.routes";
import userRouter from "./User/user.routes";
import roleRouter from "./Role/role.routes";
const v1: Router = Router();

v1.use("/auth", authRouter);
v1.use("/user", userRouter);
v1.use("/roles", roleRouter);

export default v1;
