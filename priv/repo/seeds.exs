alias WebBait.Repo
alias WebBait.Accounts.User
#
Repo.insert!(User.registration_changeset(%User{}, %{"username" => "admin", "firstName" => "Admin", "email" => "admin@localhost.local", "password" => "admin", "type" => "admin"}, hashpassword: true))
Repo.insert!(User.registration_changeset(%User{}, %{"username" => "user", "firstName" => "User", "email" => "user@localhost.local", "password" => "user", "type" => "user"}, hashpassword: true))
