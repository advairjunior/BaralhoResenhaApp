namespace BaralhoResenhaApp.Api.Dominio;

/// <param name="Jogadores">Quem leva; empate leva junto (até três).</param>
public sealed record Premio(string Emoji, string Titulo, string Descricao, IReadOnlyList<Guid> Jogadores);

/// <param name="CartaDaNoite">A carta que mais rendeu reação; nula sem reações.</param>
public sealed record ResumoDaNoite(int Cartas, int Minutos, int Goles, int Pontos, CartaDaNoite? CartaDaNoite = null);

/// <summary>
/// Os prêmios saem das estatísticas da noite. Prêmio sem ninguém pontuando
/// não aparece: melhor poucos prêmios engraçados que uma lista de zeros.
/// </summary>
public static class PremiosDaNoite
{
    private const int MaximoDeGanhadores = 3;

    public static IReadOnlyList<Premio> Calcular(IReadOnlyList<Jogador> jogadores, IReadOnlyList<(Jogador Um, Jogador Outro)> casais)
    {
        var premios = new List<Premio>();

        void Individual(string emoji, string titulo, Func<Jogador, int> valor, Func<int, Jogador, string> descricao, int minimo = 1)
        {
            if (jogadores.Count == 0) return;
            var maximo = jogadores.Max(valor);
            if (maximo < minimo) return;
            var ganhadores = jogadores.Where(j => valor(j) == maximo).ToList();
            if (ganhadores.Count > MaximoDeGanhadores) return;
            premios.Add(new Premio(emoji, titulo, descricao(maximo, ganhadores[0]), ganhadores.Select(j => j.Id).ToList()));
        }

        void DoCasal(string emoji, string titulo, Func<Jogador, int> valor, Func<int, string> descricao)
        {
            if (casais.Count == 0) return;
            int DoisJuntos((Jogador Um, Jogador Outro) casal) => valor(casal.Um) + valor(casal.Outro);
            var maximo = casais.Max(DoisJuntos);
            if (maximo < 1) return;
            var ganhadores = casais.Where(c => DoisJuntos(c) == maximo).ToList();
            if (ganhadores.Count > 1) return;
            premios.Add(new Premio(emoji, titulo, descricao(maximo), [ganhadores[0].Um.Id, ganhadores[0].Outro.Id]));
        }

        Individual("🍺", "Rei(nha) da noite", j => j.Pontos,
            (n, j) => j.SemAlcool || j.Goles == 0
                ? Plural(n, "ponto", "pontos")
                : $"{Plural(n, "ponto", "pontos")} · {Plural(j.Goles, "gole", "goles")}");
        Individual("👉", "Alvo preferido da turma", j => j.Estatisticas.VotosRecebidos,
            (n, _) => $"{Plural(n, "voto", "votos")} da turma nas votações");
        Individual("💛", "Xodó da turma", j => j.Estatisticas.Elogios,
            (n, _) => $"{Plural(n, "voto", "votos")} nas cartas de elogio");
        Individual("🎤", "Contador(a) de histórias", j => j.Estatisticas.Historias,
            (n, _) => $"Foi a única pessoa que já tinha feito {Plural(n, "vez", "vezes")}");
        Individual("🧭", "Aventureiro(a) da turma", j => j.Estatisticas.JaFiz,
            (n, _) => $"Respondeu \"já fiz\" {Plural(n, "vez", "vezes")}", minimo: 2);
        Individual("😇", "Santo(a) da turma", j => j.Estatisticas.NuncaFiz - j.Estatisticas.JaFiz,
            (_, j) => $"Só {j.Estatisticas.JaFiz} \"já fiz\" em {j.Estatisticas.JaFiz + j.Estatisticas.NuncaFiz} cartas",
            minimo: 3);
        Individual("🎭", "Artista da mímica", j => j.Estatisticas.MimicasAcertadas,
            (n, _) => $"O time acertou {Plural(n, "mímica", "mímicas")}", minimo: 2);
        Individual("⚔️", "Rei(nha) dos duelos", j => j.Estatisticas.DuelosVencidos,
            (n, _) => $"Venceu {Plural(n, "duelo", "duelos")}", minimo: 2);
        Individual("🃏", "Mestre das cartas na manga", j => j.Estatisticas.CartasUsadas,
            (n, _) => $"Usou {Plural(n, "carta", "cartas")} na manga", minimo: 2);
        Individual("🚨", "Vacilão(ona) da regra", j => j.Estatisticas.Vacilos,
            (n, _) => $"Quebrou as regras {Plural(n, "vez", "vezes")}", minimo: 2);
        Individual("🕵️", "Mestre do disfarce", j => j.Estatisticas.Disfarces,
            (n, _) => $"Foi o impostor e escapou {Plural(n, "vez", "vezes")}");
        Individual("🤥", "Mentiroso(a) de respeito", j => j.Estatisticas.MentirasPerfeitas,
            (n, _) => $"Enganou a turma inteira {Plural(n, "vez", "vezes")}");
        Individual("👮", "Fiscal da resenha", j => j.Estatisticas.Tiradas,
            (n, _) => $"Tirou {Plural(n, "carta", "cartas")} do baralho", minimo: 2);
        DoCasal("💞", "Casal em sintonia", j => j.Estatisticas.Acertos,
            n => $"Acertaram {Plural(n, "palpite", "palpites")} um sobre o outro");
        DoCasal("😬", "Casal que precisa conversar", j => j.Estatisticas.Erros,
            n => $"Erraram {Plural(n, "palpite", "palpites")} um sobre o outro");

        return premios;
    }

    public static ResumoDaNoite Resumir(Sala sala, IReadOnlyList<Jogador> jogadores)
    {
        var minutos = sala.ComecouEm is { } inicio
            ? (int)Math.Round(((sala.TerminouEm ?? inicio) - inicio).TotalMinutes)
            : 0;
        return new ResumoDaNoite(
            sala.Rodada?.Numero ?? 0,
            Math.Max(minutos, 0),
            jogadores.Where(j => !j.SemAlcool).Sum(j => j.Goles),
            jogadores.Where(j => j.SemAlcool).Sum(j => j.Pontos),
            sala.EscolherCartaDaNoite());
    }

    private static string Plural(int n, string um, string varios) => $"{n} {(n == 1 ? um : varios)}";
}
