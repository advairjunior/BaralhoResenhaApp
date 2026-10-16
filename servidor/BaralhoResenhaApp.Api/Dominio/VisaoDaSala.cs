namespace BaralhoResenhaApp.Api.Dominio;

/// <param name="Foto">Caminho da selfie na API; nulo para quem não tirou.</param>
/// <param name="ParId">Par do casal na sala, se marcou.</param>
public sealed record JogadorVisivel(
    Guid Id, string Nome, bool Anfitriao, bool SemAlcool, int Pontos, int Cofrinho, int Goles, bool Respondeu,
    string? Foto, Guid? ParId, int CartasNaManga);

/// <param name="Palpiteiro">Casais em Jogo: quem tenta adivinhar.</param>
/// <param name="Alvo">Casais em Jogo: de quem é a pergunta.</param>
public sealed record RodadaVisivel(
    int Numero,
    ModoDeJogo Modo,
    NivelDaCarta Nivel,
    string Texto,
    bool PedeResposta,
    string? MinhaResposta,
    int Respostas,
    bool EuBebi,
    IReadOnlyList<Guid> Beberam,
    Revelacao? Revelacao,
    Guid? Palpiteiro,
    Guid? Alvo,
    bool? Acertou,
    bool Votacao,
    bool Elogio,
    int? Favorito,
    IReadOnlyList<Guid> BebemAgora,
    IReadOnlyList<Guid> Vacilaram,
    IReadOnlyList<Guid> Duelistas,
    IReadOnlyList<TimeDaMimica> Times,
    string? Dica,
    int? Goles,
    bool Jokenpo,
    IReadOnlyList<string> Empates,
    int? CronometroSegundos,
    int? CronometroRestanteMs,
    IReadOnlyList<UsoDeCarta> Usos,
    IReadOnlyList<Guid> Ganharam,
    IReadOnlyList<Guid> Pegos,
    IReadOnlyList<Guid> Prontos,
    int? PassaEmMs,
    string? SeguradaPor,
    IReadOnlyList<Pendente> Pendentes,
    string CartaId,
    bool VezDaRegra,
    bool ContaEssa);

/// <summary>Esquenta sozinho: em que nível a noite está e quando sobe.</summary>
/// <param name="SobeEm">Cartas até subir; nulo quando já chegou ao limite.</param>
/// <param name="SubiuAgora">Esta é a primeira carta do nível novo.</param>
public sealed record EsquentaVisivel(NivelDaCarta Agora, NivelDaCarta Ate, int? SobeEm, bool SubiuAgora);

public sealed record MomentoVisivel(string Id, Guid JogadorId, string Nome, int Rodada, string Texto, string Foto);

/// <summary>
/// O que um celular enxerga da sala. As respostas dos outros só aparecem
/// depois da revelação: antes, cada um sabe apenas quem já respondeu.
/// </summary>
/// <param name="Premios">Só no fim da noite.</param>
public sealed record VisaoDaSala(
    string Codigo,
    FaseDaSala Fase,
    Guid EuId,
    bool SouAnfitriao,
    ConfiguracaoDoJogo Configuracao,
    IReadOnlyList<JogadorVisivel> Jogadores,
    RodadaVisivel? Rodada,
    RegraAtiva? Regra,
    IReadOnlyList<MomentoVisivel> Momentos,
    IReadOnlyList<Premio>? Premios,
    ResumoDaNoite? Resumo,
    EsquentaVisivel? Esquenta,
    string? CartaTiradaPor,
    IReadOnlyList<CartaNaManga> MinhaMao)
{
    internal static VisaoDaSala Montar(Sala sala, Jogador eu, IReadOnlyList<Jogador> jogadores)
    {
        var rodada = sala.Rodada;
        var fim = sala.Fase == FaseDaSala.Fim;
        string Endereco(FotoDoJogador foto) => $"/api/salas/{sala.Codigo}/fotos/{foto.Id}";
        return new VisaoDaSala(
            sala.Codigo,
            sala.Fase,
            eu.Id,
            eu.Anfitriao,
            sala.Configuracao,
            jogadores.Select(j => new JogadorVisivel(
                j.Id, j.Nome, j.Anfitriao, j.SemAlcool, j.Pontos, j.Cofrinho, j.Goles,
                rodada?.Respostas.ContainsKey(j.Id) ?? false,
                j.Foto is null ? null : Endereco(j.Foto),
                j.ParId,
                j.Mao.Count)).ToList(),
            rodada is null || sala.Fase is FaseDaSala.Lobby or FaseDaSala.Fim
                ? null
                : new RodadaVisivel(
                    rodada.Numero,
                    rodada.Carta.Modo,
                    rodada.Carta.Nivel,
                    rodada.TextoPara(eu.Id, sala.Fase == FaseDaSala.Revelada),
                    rodada.PedeResposta,
                    rodada.Respostas.GetValueOrDefault(eu.Id),
                    rodada.Respostas.Count,
                    rodada.Beberam.Contains(eu.Id),
                    rodada.Beberam.ToList(),
                    sala.Fase == FaseDaSala.Revelada ? rodada.Revelacao : null,
                    rodada.Palpiteiro,
                    rodada.Alvo,
                    rodada.Acertou,
                    rodada.Votacao,
                    rodada.Carta.Elogio,
                    rodada.Favorito,
                    rodada.BebemAgora.ToList(),
                    rodada.Vacilaram.ToList(),
                    rodada.Duelistas,
                    rodada.Times,
                    rodada.Dica,
                    rodada.Carta.Goles,
                    rodada.Carta.Jokenpo,
                    rodada.Empates.ToList(),
                    rodada.SegundosDoCronometro,
                    sala.RestanteDoCronometro(rodada),
                    rodada.Usos.ToList(),
                    rodada.Ganharam.ToList(),
                    rodada.Contas.Where(c => !c.Value.Vazia).Select(c => c.Key).ToList(),
                    rodada.Prontos.ToList(),
                    sala.RestanteParaPassar(rodada),
                    rodada.SeguradaPor,
                    sala.Pendentes(rodada),
                    rodada.Carta.Id,
                    rodada.VezDaRegra,
                    rodada.Carta.Conta),
            sala.Regra is { } regra ? regra with { PodemVacilar = sala.QuemPodeVacilar(regra) } : null,
            sala.Momentos.Select(m => new MomentoVisivel(
                m.Id, m.JogadorId, m.NomeDoJogador, m.Rodada, m.Texto, Endereco(m.Foto))).ToList(),
            fim ? PremiosDaNoite.Calcular(jogadores, sala.Casais()) : null,
            fim ? PremiosDaNoite.Resumir(sala, jogadores) : null,
            Esquentando(sala),
            sala.CartaTiradaPor,
            eu.Mao.ToList());
    }

    private static EsquentaVisivel? Esquentando(Sala sala)
    {
        var configuracao = sala.Configuracao;
        if (!configuracao.Esquentar || sala.Rodada is null || sala.Fase is FaseDaSala.Lobby or FaseDaSala.Fim)
            return null;
        var indice = sala.Rodada.Numero - 1;
        var agora = configuracao.NivelNaCarta(indice);
        return new EsquentaVisivel(
            agora,
            configuracao.Nivel,
            agora < configuracao.Nivel ? ConfiguracaoDoJogo.CartasPorNivel - indice % ConfiguracaoDoJogo.CartasPorNivel : null,
            indice > 0 && agora > configuracao.NivelNaCarta(indice - 1));
    }
}
