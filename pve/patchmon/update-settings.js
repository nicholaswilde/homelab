const { PrismaClient } = require('@prisma/client');
const { v4: uuidv4 } = require('uuid');
const prisma = new PrismaClient();

async function updateSettings() {
  try {
    const existingSettings = await prisma.settings.findFirst();

    const settingsData = {
      id: uuidv4(),
      server_url: 'http://192.168.2.187',
      server_protocol: 'http',
      server_host: '192.168.2.187',
      server_port: 3399,
      update_interval: 60,
      auto_update: true,
      signup_enabled: false,
      ignore_ssl_self_signed: false,
      updated_at: new Date()
    };

  if (existingSettings) {
    // Update existing settings
    await prisma.settings.update({
      where: { id: existingSettings.id },
      data: settingsData
    });
  } else {
    // Create new settings record
    await prisma.settings.create({
      data: settingsData
    });
  }

  console.log('✅ Database settings updated successfully');
  } catch (error) {
    console.error('❌ Error updating settings:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

updateSettings();
