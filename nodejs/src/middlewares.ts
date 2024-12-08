import { getCookie } from "hono/cookie";
import { createMiddleware } from "hono/factory";
import type { RowDataPacket } from "mysql2/promise";
import type { Environment } from "./types/hono.js";
import type { Chair, Owner, User } from "./types/models.js";

const onMemoryUsers = new Map<string, User & RowDataPacket>();
const onMemoryOwners = new Map<string, Owner & RowDataPacket>();
const onMemoryChairs = new Map<string, Chair & RowDataPacket>();

export const clearOnMemories = () => {
  onMemoryUsers.clear();
  onMemoryOwners.clear();
  onMemoryChairs.clear();
};

export const appAuthMiddleware = createMiddleware<Environment>(
  async (ctx, next) => {
    const accessToken = getCookie(ctx, "app_session");
    if (!accessToken) {
      return ctx.text("app_session cookie is required", 401);
    }
    if (onMemoryUsers.has(accessToken)) {
      ctx.set("user", onMemoryUsers.get(accessToken)!);
      return next();
    }
    try {
      const [[user]] = await ctx.var.dbConn.query<Array<User & RowDataPacket>>(
        "SELECT * FROM users WHERE access_token = ?",
        [accessToken],
      );
      if (!user) {
        return ctx.text("invalid access token", 401);
      }
      onMemoryUsers.set(accessToken, user);
      ctx.set("user", user);
    } catch (error) {
      return ctx.text(`Internal Server Error\n${error}`, 500);
    }
    await next();
  },
);

export const ownerAuthMiddleware = createMiddleware<Environment>(
  async (ctx, next) => {
    const accessToken = getCookie(ctx, "owner_session");
    if (!accessToken) {
      return ctx.text("owner_session cookie is required", 401);
    }
    if (onMemoryOwners.has(accessToken)) {
      ctx.set("owner", onMemoryOwners.get(accessToken)!);
      return next();
    }
    try {
      const [[owner]] = await ctx.var.dbConn.query<
        Array<Owner & RowDataPacket>
      >("SELECT * FROM owners WHERE access_token = ?", [accessToken]);
      if (!owner) {
        return ctx.text("invalid access token", 401);
      }
      onMemoryOwners.set(accessToken, owner);
      ctx.set("owner", owner);
    } catch (error) {
      return ctx.text(`Internal Server Error\n${error}`, 500);
    }
    await next();
  },
);

export const chairAuthMiddleware = createMiddleware<Environment>(
  async (ctx, next) => {
    const accessToken = getCookie(ctx, "chair_session");
    if (!accessToken) {
      return ctx.text("chair_session cookie is required", 401);
    }
    if (onMemoryChairs.has(accessToken)) {
      ctx.set("chair", onMemoryChairs.get(accessToken)!);
      return next();
    }
    try {
      const [[chair]] = await ctx.var.dbConn.query<
        Array<Chair & RowDataPacket>
      >("SELECT * FROM chairs WHERE access_token = ?", [accessToken]);
      if (!chair) {
        return ctx.text("invalid access token", 401);
      }
      onMemoryChairs.set(accessToken, chair);
      ctx.set("chair", chair);
    } catch (error) {
      return ctx.text(`Internal Server Error\n${error}`, 500);
    }
    await next();
  },
);
