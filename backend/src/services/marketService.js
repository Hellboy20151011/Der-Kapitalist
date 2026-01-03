const RES_TYPES = ['water', 'wood', 'stone'];

export const MARKET = {
  feePercent: 7,
  maxActiveListingsPerUser: 10,
  listingHours: 24
};

export function isValidResourceType(t) {
  return RES_TYPES.includes(t);
}

export async function countActiveListings(client, userId) {
  const r = await client.query(
    `SELECT COUNT(*)::int AS c
     FROM market_listings
     WHERE seller_user_id = $1 AND status = 'active' AND expires_at > now()`,
    [userId]
  );
  return r.rows[0].c;
}

export async function expireListingIfNeeded(client, listingRow) {
  if (listingRow.status !== 'active') return listingRow;
  const expiresAt = new Date(listingRow.expires_at);
  if (expiresAt.getTime() <= Date.now()) {
    await client.query(
      `UPDATE market_listings SET status = 'expired' WHERE id = $1`,
      [listingRow.id]
    );
    return { ...listingRow, status: 'expired' };
  }
  return listingRow;
}