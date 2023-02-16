alias WebBait.Repo
alias WebBait.Accounts.User
#
Repo.insert!(User.registration_changeset(%User{}, %{"username" => "admin", "password" => "admin", "type" => "admin"}, hashpassword: true))
