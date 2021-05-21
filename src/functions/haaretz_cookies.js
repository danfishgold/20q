const cookies = {
  HtzPusr: process.env.COOKIE_HTZ_PUSR,
  productsStatus: process.env.COOKIE_PRODUCTS_STATUS,
  tmsso: process.env.COOKIE_TMSSO,
  userProducts: process.env.COOKIE_USER_PRODUCTS,
  tmpPersistentuserId: process.env.COOKIE_TMP_PERSISTENT_USER_ID,
  TmUserId: process.env.COOKIE_TM_USER_ID,
  'permutive-id': process.env.COOKIE_PERMUTIVE_ID,
  'permutive-session': process.env.COOKIE_PERMUTIVE_SESSION,
}

module.exports = { cookies }
