BEGIN;
CREATE OR REPLACE FUNCTION touch_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN NEW.updated_at=now(); RETURN NEW; END $$;
CREATE TRIGGER trg_users_updated BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_books_updated BEFORE UPDATE ON books FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE OR REPLACE FUNCTION normalize_email() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN NEW.email=lower(trim(NEW.email)); RETURN NEW; END $$;
CREATE TRIGGER trg_users_email BEFORE INSERT OR UPDATE OF email ON users FOR EACH ROW EXECUTE FUNCTION normalize_email();
CREATE OR REPLACE FUNCTION ensure_primary_image() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF NEW.is_primary THEN UPDATE book_images SET is_primary=false WHERE book_id=NEW.book_id AND id<>COALESCE(NEW.id,0); END IF; RETURN NEW; END $$;
CREATE TRIGGER trg_one_primary_image BEFORE INSERT OR UPDATE OF is_primary ON book_images FOR EACH ROW EXECUTE FUNCTION ensure_primary_image();
COMMIT;
