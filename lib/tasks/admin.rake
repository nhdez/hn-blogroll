namespace :admin do
  desc "Create an admin user"
  task :create => :environment do
    email = ENV['ADMIN_EMAIL'] || 'admin@example.com'
    password = ENV['ADMIN_PASSWORD'] || 'password123'
    
    if User.exists?(email: email)
      puts "Admin user with email #{email} already exists"
    else
      user = User.create!(
        email: email,
        password: password,
        password_confirmation: password,
        admin: true
      )
      puts "Admin user created with email: #{email}"
      puts "Password: #{password}"
    end
  end
  
  desc "List all admin users"
  task :list => :environment do
    admins = User.admins
    if admins.any?
      puts "Admin users:"
      admins.each do |admin|
        puts "- #{admin.email} (created: #{admin.created_at})"
      end
    else
      puts "No admin users found"
    end
  end
end