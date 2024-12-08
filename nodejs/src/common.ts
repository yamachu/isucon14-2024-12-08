import type { Connection, RowDataPacket } from "mysql2/promise";
import type { Ride, RideStatus } from "./types/models.js";

export const INITIAL_FARE = 500;
export const FARE_PER_DISTANCE = 100;

// マンハッタン距離を求める
export const calculateDistance = (
  aLatitude: number,
  aLongitude: number,
  bLatitude: number,
  bLongitude: number,
): number => {
  return Math.abs(aLatitude - bLatitude) + Math.abs(aLongitude - bLongitude);
};

export const calculateFare = (
  pickupLatitude: number,
  pickupLongitude: number,
  destLatitude: number,
  destLongitude: number,
): number => {
  const meterdFare =
    FARE_PER_DISTANCE *
    calculateDistance(
      pickupLatitude,
      pickupLongitude,
      destLatitude,
      destLongitude,
    );
  return INITIAL_FARE + meterdFare;
};

export const calculateSale = (ride: Ride): number => {
  return calculateFare(
    ride.pickup_latitude,
    ride.pickup_longitude,
    ride.destination_latitude,
    ride.destination_longitude,
  );
};

export const getLatestRideStatus = async (
  dbConn: Connection,
  rideId: string,
): Promise<RideStatus> => {
  const [[rideStatus]] = await dbConn.query<Array<RideStatus & RowDataPacket>>(
    "SELECT * FROM ride_statuses_latest WHERE ride_id = ?",
    [rideId],
  );
  return rideStatus;
};

const latestRideByChairId = new Map<string, Ride>();
export const flushLatestRideByChairId = (chairId: string): void => {
  latestRideByChairId.delete(chairId);
};

export const clearOnMemoryLatest = () => {
  latestRideByChairId.clear();
};

export const getLatestRideByChairId = async (
  dbConn: Connection,
  chairId: string,
): Promise<Ride> => {
  if (latestRideByChairId.has(chairId)) {
    return latestRideByChairId.get(chairId)!;
  }
  const [[ride]] = await dbConn.query<Array<Ride & RowDataPacket>>(
    "SELECT * FROM rides WHERE chair_id = ? ORDER BY created_at DESC",
    [chairId],
  );
  return ride;
};

export class ErroredUpstream extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ErroredUpstream";
  }
}
