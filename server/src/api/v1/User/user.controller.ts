import { Request, Response } from "express";
import { injectable } from "tsyringe";
import UserService from "./user.service";

@injectable()
export default class UserController {
    constructor(private userService: UserService) {}

    async register(req: Request, res: Response) {
        try {
            const { email, password, firstName, lastName } = req.body;
            
            const user = await this.userService.createUser({ email, firstName, lastName });
            res.status(201).json({ user });
        } catch (error) {
            res.status(400).json({ error: (error as Error).message });
        }
    }

    async getProfile(req: Request, res: Response) {
        try {
            const userId = req.user?.id;
            if (!userId) {
                return res.status(401).json({ error: "Unauthorized" });
            }
            const user = await this.userService.getUserById(userId);
            res.json({ user });
        } catch (error) {
            res.status(400).json({ error: (error as Error).message });
        }
    }

    async updateProfile(req: Request, res: Response) {
        try {
            const userId = req.user?.id;
            if (!userId) {
                return res.status(401).json({ error: "Unauthorized" });
            }
            const { firstName, lastName } = req.body;
            const user = await this.userService.updateUser(userId, { firstName, lastName });
            res.json({ user });
        } catch (error) {
            res.status(400).json({ error: (error as Error).message });
        }
    }
}
