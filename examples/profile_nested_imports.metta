!(import! &self profile/outer_import)

!(test (profile-outer 2500 150 0) 375000)
