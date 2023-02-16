alias WebBait.Repo
alias WebBait.Accounts.User
#
Repo.insert!(User.registration_changeset(%User{}, %{"username" => "admin", "firstName" => "Admin", "email" => "admin@localhost.local", "password" => "admin", "type" => "admin"}, hashpassword: true))
