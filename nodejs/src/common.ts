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

const latestRideStatus = new Map<string, RideStatus>();
export const clearOnMemoryLatestRideStatus = () => {
  latestRideStatus.clear();
};
export const purgeOldRideStatus = (rideId: string) => {
  latestRideStatus.delete(rideId);
};

export const getLatestRideStatus = async (
  dbConn: Connection,
  rideId: string,
): Promise<RideStatus> => {
  const maybe = latestRideStatus.get(rideId);
  if (maybe) {
    return maybe;
  }
  const [[rideStatus]] = await dbConn.query<Array<RideStatus & RowDataPacket>>(
    "SELECT * FROM ride_statuses_latest WHERE ride_id = ?",
    [rideId],
  );
  latestRideStatus.set(rideId, rideStatus);
  return rideStatus;
};

export class ErroredUpstream extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ErroredUpstream";
  }
}
