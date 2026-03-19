# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_19_002521) do
  create_table "ag_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "status", default: "pending", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_ag_sessions_on_token", unique: true
  end

  create_table "choices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_other", default: false, null: false
    t.integer "position", default: 0, null: false
    t.integer "question_id", null: false
    t.string "text", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_choices_on_question_id"
  end

  create_table "participants", force: :cascade do |t|
    t.integer "ag_session_id", null: false
    t.datetime "claimed_at"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["ag_session_id"], name: "index_participants_on_ag_session_id"
    t.index ["token"], name: "index_participants_on_token", unique: true
  end

  create_table "questions", force: :cascade do |t|
    t.integer "ag_session_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.string "text", null: false
    t.datetime "updated_at", null: false
    t.index ["ag_session_id"], name: "index_questions_on_ag_session_id"
  end

  create_table "votes", force: :cascade do |t|
    t.integer "choice_id", null: false
    t.datetime "created_at", null: false
    t.text "free_text"
    t.integer "participant_id", null: false
    t.integer "question_id", null: false
    t.datetime "updated_at", null: false
    t.index ["choice_id"], name: "index_votes_on_choice_id"
    t.index ["participant_id", "question_id"], name: "index_votes_on_participant_id_and_question_id", unique: true
    t.index ["participant_id"], name: "index_votes_on_participant_id"
    t.index ["question_id"], name: "index_votes_on_question_id"
  end

  add_foreign_key "choices", "questions"
  add_foreign_key "participants", "ag_sessions"
  add_foreign_key "questions", "ag_sessions"
  add_foreign_key "votes", "choices"
  add_foreign_key "votes", "participants"
  add_foreign_key "votes", "questions"
end
