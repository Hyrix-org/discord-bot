use poise::serenity_prelude::{self as serenity, ApplicationId};
use sea_orm::DatabaseConnection;

mod commands;
mod moderation;
mod translation;

pub struct Data {
    pub db: DatabaseConnection,
    translations: translation::Translations,
}

pub static APPID: ApplicationId = ApplicationId::new(1129023481892306965);

pub type Error = Box<dyn std::error::Error + Send + Sync>;
pub type Context<'a> = poise::Context<'a, Data, Error>;

#[tokio::main]
async fn main() -> Result<(), Error> {
    tracing_subscriber::fmt::init();

    // Database
    let database_url =
        std::env::var("DATABASE_URL").unwrap_or("sqlite:db.sqlite?mode=rwc".to_string());
    let db = sea_orm::Database::connect(database_url).await?;

    // Commands
    let mut commands = vec![commands::help()];

    // Translations
    let translations = translation::read_ftl().expect("failed to read translation files");
    translation::apply_translations(&translations, &mut commands);

    // Run migrations
    //sea_orm_migration::MigratorTrait::run(&db, entities::migration::Migrator).await?;

    let intents = serenity::GatewayIntents::all();

    let framework = poise::Framework::builder()
        .options(poise::FrameworkOptions {
            commands,
            event_handler: |ctx, event, framework, data| {
                Box::pin(event_handler(ctx, event, framework, data))
            },
            ..Default::default()
        })
        .setup(|ctx, _ready, framework| {
            Box::pin(async move {
                poise::builtins::register_globally(ctx, &framework.options().commands).await?;

                let data = Data { db, translations };

                //tokio::spawn(api::start_api_server(data.db.clone(), ctx.http.clone()));

                Ok(data)
            })
        })
        .build();

    let token = std::env::var("DISCORD_TOKEN").expect("DISCORD_TOKEN must be set");
    let mut client = serenity::ClientBuilder::new(token, intents)
        .framework(framework)
        .application_id(APPID)
        .await?;

    client.start().await?;
    Ok(())
}

async fn event_handler(
    ctx: &serenity::Context,
    event: &serenity::FullEvent,
    _framework: poise::FrameworkContext<'_, Data, Error>,
    data: &Data,
) -> Result<(), Error> {
    match event {
        serenity::FullEvent::Ready { data_about_bot } => {
            tracing::info!(
                "{} is connected! Slash commands registered globally.",
                data_about_bot.user.name
            );
        }
        serenity::FullEvent::Message { new_message } => {
            if new_message.author.bot {
                return Ok(());
            }

            // Word filter check
            //     if let Some(guild_id) = new_message.guild_id {
            //         if moderation::check_word_filter(&data.word_filter, &new_message.content).await {
            //             let _ = new_message.delete(&ctx.http).await;
            //             logging::log_filtered_message(
            //                 &data.db,
            //                 guild_id,
            //                 new_message.author.id,
            //                 &new_message.content,
            //             )
            //             .await?;
            //
            //             let warning = format!(
            //                 "<@{}> Your message contained inappropriate content and was removed.",
            //                 new_message.author.id
            //             );
            //             let _ = new_message.channel_id.say(&ctx.http, warning).await;
            //         }
            //     }
        } // serenity::FullEvent::InteractionCreate { interaction } => {
        //     if let serenity::Interaction::Component(component) = &interaction {
        //         //dashboard::handle_component_interaction(ctx, component, data).await?;
        //     }
        // }
        _ => {}
    }
    Ok(())
}
