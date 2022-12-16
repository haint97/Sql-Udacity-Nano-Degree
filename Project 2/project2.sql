CREATE DATABASE udiddit;

USE udiddit;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(25) UNIQUE NOT NULL,
    datetime_last_login TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX index_user_lastlogin ON users (datetime_last_login);



CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    topic_name VARCHAR(30) UNIQUE NOT NULL,
    topic_description VARCHAR(500),
    datetime_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    --user_id BIGINT UNSIGNED FOREIGN KEY (user_id) REFERENCES users (id)
);


CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    url TEXT,
    content TEXT,
    topic_id BIGINT  NOT NULL REFERENCES topics (id) ON DELETE CASCADE,
    user_id BIGINT  REFERENCES users (id) ON DELETE SET NULL,
    datetime_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT post_url_or_content CHECK ((url IS NOT NULL AND content IS NULL)
        OR (content IS NOT NULL AND url IS NULL))
);

CREATE INDEX index_post_title ON posts (title);


CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    parent_id BIGINT  REFERENCES comments (id) ON DELETE CASCADE,
    post_id BIGINT  NOT NULL  REFERENCES posts (id) ON DELETE CASCADE,
    user_id BIGINT   REFERENCES users (id) ON DELETE SET NULL,
    datetime_created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE votes (
    id SERIAL PRIMARY KEY,
    up_vote INT,
    down_vote INT,
    user_id BIGINT  REFERENCES users (id)  ON DELETE SET NULL,
    post_id BIGINT  NOT NULL REFERENCES posts (id) ON DELETE CASCADE,
    CONSTRAINT vote_value CHECK ((up_vote = 1 AND down_vote IS NULL)
        OR (down_vote = - 1 AND up_vote IS NULL)),
    CONSTRAINT unique_votes UNIQUE (user_id , post_id)
);

------ Populating data
INSERT INTO users (username) 
	SELECT DISTINCT LEFT(TRIM(bp.username),25)  --
		FROM bad_posts as bp
	UNION
	SELECT DISTINCT LEFT(TRIM(bc.username),25)
		FROM bad_comments AS bc;

INSERT INTO topics (topic_name)
	SELECT DISTINCT LEFT(TRIM(bp.topic),30) 
		FROM bad_posts AS bp
    JOIN users AS u
		ON u.username = bp.username


INSERT INTO posts (title, url, content, topic_id, user_id)
	SELECT LEFT(bp.title, 100), bp.url, bp.text_content, t.id, u.id
		FROM bad_posts AS bp
	JOIN topics AS t
		ON bp.topic = t.topic_name
	JOIN users AS u
		ON bp.username = u.username;


INSERT INTO comments(content, post_id, user_id)
	SELECT bc.text_content, p.id, u.id
		FROM bad_comments AS bc
	JOIN bad_posts AS bp 
		ON bc.post_id = bp.id
	JOIN posts AS p 
		ON p.title = bp.title
	JOIN users AS u 
		ON bc.username = u.username;

INSERT INTO votes(down_vote, user_id, post_id)
    SELECT -1, u.id, post_user.id
    FROM (
        SELECT id, REGEXP_SPLIT_TO_TABLE(downvotes, ',') AS down_vote_user
        FROM bad_posts 
    ) AS post_user
    JOIN users AS u ON u.username = post_user.down_vote_user



INSERT INTO votes(up_vote, user_id, post_id)
    SELECT 1, u.id, post_user.id
    FROM (
        SELECT id, REGEXP_SPLIT_TO_TABLE(upvotes, ',') AS up_vote_user
        FROM bad_posts 
    ) AS post_user
    JOIN users AS u ON u.username = post_user.up_vote_user
