const { createRequire } = require('module')

const webRequire = createRequire('/var/www/sharelatex/web/package.json')
const { User } = webRequire('./app/src/models/User')
const bcrypt = webRequire('bcrypt')

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms))

async function seedOwner() {
  const emailRaw = process.env.OVERLEAF_ADMIN_EMAIL || ''
  const password = process.env.OVERLEAF_ADMIN_PASSWORD || ''
  const email = String(emailRaw).trim().toLowerCase()

  if (!email || email === 'owner@example.com') {
    console.log('seed-owner: skipped (OVERLEAF_ADMIN_EMAIL not set to a real value)')
    return
  }

  if (!password || password === 'change-me-now') {
    console.log('seed-owner: skipped (OVERLEAF_ADMIN_PASSWORD not set to a real value)')
    return
  }

  let user = await User.findOne({ email }).exec()

  if (!user) {
    user = new User({
      email,
      emails: [{ email }],
      first_name: 'Owner',
      last_name: '',
      holdingAccount: false,
    })
  }

  if (!Array.isArray(user.emails) || user.emails.length === 0) {
    user.emails = [{ email }]
  }

  user.email = email
  user.holdingAccount = false
  user.hashedPassword = await bcrypt.hash(password, 12)

  await user.save()
  console.log(`seed-owner: ready (${email})`)
}

async function run() {
  // Keep retrying until Mongo replica set is initialized and writable.
  for (;;) {
    try {
      await seedOwner()
      process.exit(0)
    } catch (error) {
      console.log(`seed-owner: retrying in 5s (${error.message})`)
      await sleep(5000)
    }
  }
}

run()
