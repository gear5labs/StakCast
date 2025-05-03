import { Router } from "express";
import { container } from "tsyringe";
import AuthController from "./AuthController";
import RouteErrorHandler from "../../../utils/errorHandler";
import { silentAuthMiddleware } from "../../../middleware/silentAuth.middleware";

const authRouter = Router();
const authController = container.resolve(AuthController);

authRouter.post("/login", RouteErrorHandler(authController.login.bind(authController)));
authRouter.post("/refresh", RouteErrorHandler(authController.silentRefresh.bind(authController)));
authRouter.post("/register", RouteErrorHandler(authController.register.bind(authController)));

authRouter.use(silentAuthMiddleware);
// Add protected routes here

export default authRouter;
