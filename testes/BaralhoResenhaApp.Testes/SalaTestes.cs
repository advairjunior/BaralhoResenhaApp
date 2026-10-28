using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

public sealed class SalaTestes
{
    private static readonly ConfiguracaoDoJogo SoEuNunca =
        new(NivelDaCarta.Leve, [ModoDeJogo.EuNunca], ZonaSegura: true);
    private static readonly ConfiguracaoDoJogo SoMaisProvavel =
        new(NivelDaCarta.Leve, [ModoDeJogo.MaisProvavel], ZonaSegura: true);
    private static readonly ConfiguracaoDoJogo SoBebaSe =
        new(NivelDaCarta.Leve, [ModoDeJogo.BebaSe], ZonaSegura: true);

    private static Baralho BaralhoDeTeste() => new([
        new Carta("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca 1"),
        new Carta("en-2", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca 2"),
        new Carta("mp-1", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve, "Quem 1"),
        new Carta("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Bebe quem está ao lado de {jogador}"),
        new Carta("rr-1", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve, "Proibido 1"),
    ]);

    private static (Sala sala, Jogador ana, Jogador bia, Jogador caio) SalaComTres(
        ConfiguracaoDoJogo configuracao, double chanceDeVotacao = 1)
    {
        var sala = new Sala("ABCD", BaralhoDeTeste(), new Random(1));
        var ana = sala.Entrar("Ana", semAlcool: false);
        var bia = sala.Entrar("Bia", semAlcool: true);
        var caio = sala.Entrar("Caio", semAlcool: false);
        sala.ChanceDeVotacao = chanceDeVotacao;
        sala.Configurar(ana.Token, configuracao);
        sala.Comecar(ana.Token);
        return (sala, ana, bia, caio);
    }

    [Fact]
    public void QuemCriaASalaEhOAnfitriao()
    {
        var sala = new Sala("ABCD", BaralhoDeTeste());
        var ana = sala.Entrar("Ana", false);
        var bia = sala.Entrar("Bia", false);

        Assert.True(ana.Anfitriao);
        Assert.False(bia.Anfitriao);
    }

    [Fact]
    public void NomeRepetidoNaMesmaSalaEhRecusado()
    {
        var sala = new Sala("ABCD", BaralhoDeTeste());
        sala.Entrar("Ana", false);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => sala.Entrar(" ana ", false));
        Assert.Equal(Sala.MensagemDeNomeEmUso, erro.Message);
    }

    [Fact]
    public void NaoComecaSozinho()
    {
        var sala = new Sala("ABCD", BaralhoDeTeste());
        var ana = sala.Entrar("Ana", false);

        Assert.Throws<AcaoNaoPermitidaException>(() => sala.Comecar(ana.Token));
    }

    [Fact]
    public void SoOAnfitriaoConfiguraEComeca()
    {
        var sala = new Sala("ABCD", BaralhoDeTeste());
        sala.Entrar("Ana", false);
        var bia = sala.Entrar("Bia", false);

        Assert.Throws<AcaoNaoPermitidaException>(() => sala.Configurar(bia.Token, SoEuNunca));
        Assert.Throws<AcaoNaoPermitidaException>(() => sala.Comecar(bia.Token));
    }

    [Fact]
    public void RespostasDosOutrosFicamEscondidasAteARevelacao()
    {
        var (sala, ana, bia, _) = SalaComTres(SoEuNunca);
        var rodada = sala.Rodada!.Numero;

        sala.Responder(ana.Token, rodada, Sala.RespostaJa);
        var visaoDaBia = sala.Visao(bia.Token);

        Assert.Equal(FaseDaSala.Carta, visaoDaBia.Fase);
        Assert.Null(visaoDaBia.Rodada!.Revelacao);
        Assert.Null(visaoDaBia.Rodada.MinhaResposta);
        Assert.Equal(1, visaoDaBia.Rodada.Respostas);
        Assert.True(visaoDaBia.Jogadores.Single(j => j.Nome == "Ana").Respondeu);
        Assert.Equal(Sala.RespostaJa, sala.Visao(ana.Token).Rodada!.MinhaResposta);
    }

    [Fact]
    public void EuNuncaRevelaQuandoTodosRespondemEQuemJaFezBebe()
    {
        var (sala, ana, bia, caio) = SalaComTres(SoEuNunca);
        var rodada = sala.Rodada!.Numero;

        sala.Responder(ana.Token, rodada, Sala.RespostaJa);
        sala.Responder(bia.Token, rodada, Sala.RespostaNunca);
        sala.Responder(caio.Token, rodada, Sala.RespostaNunca);

        var revelacao = sala.Visao(bia.Token).Rodada!.Revelacao!;
        Assert.Equal(FaseDaSala.Revelada, sala.Fase);
        Assert.Equal([ana.Id], revelacao.JaFizeram);
        Assert.Equal([ana.Id], revelacao.Perderam);
        Assert.Equal(ana.Id, revelacao.ContaAHistoria);
        Assert.Equal(1, ana.Pontos);
        Assert.Equal(0, bia.Pontos);
    }

    [Fact]
    public void SoTemHistoriaQuandoUmaUnicaPessoaJaFez()
    {
        var (sala, ana, bia, caio) = SalaComTres(SoEuNunca);
        var rodada = sala.Rodada!.Numero;

        sala.Responder(ana.Token, rodada, Sala.RespostaJa);
        sala.Responder(bia.Token, rodada, Sala.RespostaJa);
        sala.Responder(caio.Token, rodada, Sala.RespostaNunca);

        Assert.Null(sala.Rodada.Revelacao!.ContaAHistoria);
    }

    [Fact]
    public void RevelarAgoraNaoEsperaQuemNaoRespondeu()
    {
        var (sala, ana, bia, _) = SalaComTres(SoEuNunca);
        var rodada = sala.Rodada!.Numero;

        sala.Responder(ana.Token, rodada, Sala.RespostaNunca);
        sala.Responder(bia.Token, rodada, Sala.RespostaJa);
        sala.Revelar(ana.Token, rodada);

        Assert.Equal(FaseDaSala.Revelada, sala.Fase);
        Assert.Equal([bia.Id], sala.Rodada.Revelacao!.Perderam);
    }

    [Fact]
    public void MaisProvavelOMaisVotadoBebeEEmpateTodosBebem()
    {
        var (sala, ana, bia, caio) = SalaComTres(SoMaisProvavel);
        var rodada = sala.Rodada!.Numero;

        sala.Responder(ana.Token, rodada, caio.Id.ToString());
        sala.Responder(bia.Token, rodada, ana.Id.ToString());
        sala.Responder(caio.Token, rodada, ana.Id.ToString());
        Assert.Equal([ana.Id], sala.Rodada.Revelacao!.Perderam);
        Assert.Equal(1, ana.Pontos);

        sala.Proxima(ana.Token, rodada);
        var segunda = sala.Rodada!.Numero;
        sala.Responder(ana.Token, segunda, bia.Id.ToString());
        sala.Responder(bia.Token, segunda, caio.Id.ToString());
        sala.Revelar(ana.Token, segunda);

        Assert.Equal(new[] { bia.Id, caio.Id }.Order(), sala.Rodada.Revelacao!.Perderam.Order());
        Assert.Equal(1, bia.Pontos);
        Assert.Equal(1, caio.Pontos);
    }

    [Fact]
    public void VotoEmQuemNaoEstaNaSalaEhRecusado()
    {
        var (sala, ana, _, _) = SalaComTres(SoMaisProvavel);

        Assert.Throws<AcaoNaoPermitidaException>(
            () => sala.Responder(ana.Token, sala.Rodada!.Numero, Guid.NewGuid().ToString()));
    }

    [Fact]
    public void ApontarNoTresQuemCriouASalaMarcaQuemATurmaApontou()
    {
        var (sala, ana, bia, caio) = SalaComTres(SoMaisProvavel, chanceDeVotacao: 0);
        var rodada = sala.Rodada!;

        Assert.False(rodada.Votacao);
        Assert.False(rodada.PedeResposta);
        Assert.Throws<AcaoNaoPermitidaException>(() => sala.Responder(ana.Token, rodada.Numero, bia.Id.ToString()));
        Assert.Throws<AcaoNaoPermitidaException>(() => sala.AlternarBebi(bia.Token, rodada.Numero));
        Assert.Throws<AcaoNaoPermitidaException>(() => sala.MarcarApontado(caio.Token, rodada.Numero, bia.Id));

        sala.MarcarApontado(ana.Token, rodada.Numero, bia.Id);
        Assert.Equal(1, bia.Pontos);
        Assert.Contains(bia.Id, sala.Visao(caio.Token).Rodada!.Beberam);

        sala.MarcarApontado(ana.Token, rodada.Numero, bia.Id);
        Assert.Equal(0, bia.Pontos);
    }

    [Fact]
    public void SoQuemCriouASalaPassaPulaRevelaOuTiraCarta()
    {
        var (sala, _, bia, _) = SalaComTres(SoEuNunca);
        var rodada = sala.Rodada!.Numero;
        sala.Responder(bia.Token, rodada, Sala.RespostaJa);

        foreach (var acao in new Action[]
                 {
                     () => sala.Proxima(bia.Token, rodada),
                     () => sala.Revelar(bia.Token, rodada),
                     () => sala.Tirar(bia.Token, rodada),
                 })
        {
            var erro = Assert.Throws<AcaoNaoPermitidaException>(acao);
            Assert.Equal("Só quem criou a sala puxa a próxima carta.", erro.Message);
        }
        Assert.Equal(rodada, sala.Rodada!.Numero);
    }

    [Fact]
    public void NaVotacaoNaoTemMePegou()
    {
        var (sala, ana, _, _) = SalaComTres(SoMaisProvavel);

        Assert.True(sala.Visao(ana.Token).Rodada!.Votacao);
        Assert.Throws<AcaoNaoPermitidaException>(() => sala.AlternarBebi(ana.Token, sala.Rodada!.Numero));
    }

    [Fact]
    public void VotacaoOuApontarESorteadoACadaCarta()
    {
        var (sala, ana, _, _) = SalaComTres(SoMaisProvavel, chanceDeVotacao: 0.5);
        var votacoes = 0;
        for (var i = 0; i < 200; i++)
        {
            if (sala.Rodada!.Votacao) votacoes++;
            sala.Proxima(ana.Token, sala.Rodada.Numero);
        }

        Assert.InRange(votacoes, 70, 130);
    }

    [Fact]
    public void DoisToquesEmProximaAoMesmoTempoAvancamSoUmaCarta()
    {
        var (sala, ana, bia, _) = SalaComTres(SoBebaSe);
        var rodada = sala.Rodada!.Numero;

        sala.Proxima(ana.Token, rodada);
        sala.Proxima(ana.Token, rodada);

        Assert.Equal(rodada + 1, sala.Rodada!.Numero);
    }

    [Fact]
    public void PularCartaNaoContaGole()
    {
        var (sala, ana, bia, _) = SalaComTres(SoEuNunca);
        var rodada = sala.Rodada!.Numero;

        sala.Responder(ana.Token, rodada, Sala.RespostaJa);
        sala.Proxima(ana.Token, rodada);

        Assert.Equal(0, ana.Pontos);
        Assert.Equal(FaseDaSala.Carta, sala.Fase);
    }

    [Fact]
    public void MePegouMarcaEDesmarcaOProprioGole()
    {
        var (sala, ana, _, _) = SalaComTres(SoBebaSe);
        var rodada = sala.Rodada!.Numero;

        sala.AlternarBebi(ana.Token, rodada);
        Assert.Equal(1, ana.Pontos);
        Assert.True(sala.Visao(ana.Token).Rodada!.EuBebi);

        sala.AlternarBebi(ana.Token, rodada);
        Assert.Equal(0, ana.Pontos);
    }

    [Fact]
    public void NomeDeJogadorEntraNoTextoDaCarta()
    {
        var (sala, _, _, _) = SalaComTres(SoBebaSe);

        Assert.DoesNotContain("{jogador}", sala.Rodada!.Texto);
        Assert.Contains(sala.Jogadores, j => sala.Rodada.Texto.EndsWith(j.Nome));
    }

    [Fact]
    public void DueloSorteiaDuasPessoasDiferentes()
    {
        for (var semente = 0; semente < 30; semente++)
        {
            var sala = new Sala("ABCD", new Baralho([
                new Carta("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "{jogador} contra {jogador2}"),
            ]), new Random(semente));
            var ana = sala.Entrar("Ana", false);
            sala.Entrar("Bia", false);
            sala.Entrar("Caio", false);
            sala.Configurar(ana.Token, SoBebaSe);
            sala.Comecar(ana.Token);

            var nomes = sala.Rodada!.Texto.Split(" contra ");
            Assert.NotEqual(nomes[0], nomes[1]);
            Assert.All(nomes, nome => Assert.Contains(sala.Jogadores, j => j.Nome == nome));
        }
    }

    [Fact]
    public void RegraRelampagoDuraTresCartas()
    {
        var sala = new Sala("ABCD", new Baralho([
            new Carta("rr-1", ModoDeJogo.RegraRelampago, NivelDaCarta.Leve, "Proibido falar tipo"),
            new Carta("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se 1"),
        ]), new Random(1));
        var ana = sala.Entrar("Ana", false);
        sala.Entrar("Bia", false);
        sala.Configurar(ana.Token, new(NivelDaCarta.Leve, [ModoDeJogo.RegraRelampago], true));
        sala.Comecar(ana.Token);
        Assert.Equal(new RegraAtiva("Proibido falar tipo", Sala.RodadasDaRegra), sala.Regra);

        sala.Configurar(ana.Token, SoBebaSe);
        sala.Proxima(ana.Token, sala.Rodada!.Numero);
        Assert.Equal(Sala.RodadasDaRegra, sala.Regra!.RodadasRestantes);

        for (var i = Sala.RodadasDaRegra; i > 0; i--)
        {
            Assert.NotNull(sala.Regra);
            sala.Proxima(ana.Token, sala.Rodada!.Numero);
        }
        Assert.Null(sala.Regra);
    }

    [Fact]
    public void QuandoOAnfitriaoSaiOProximoAssume()
    {
        var (sala, ana, bia, _) = SalaComTres(SoEuNunca);

        sala.Sair(ana.Token);

        Assert.True(bia.Anfitriao);
        Assert.Throws<JogadorNaoReconhecidoException>(() => sala.Visao(ana.Token));
    }

    [Fact]
    public void SeQuemFaltavaResponderSaiARodadaRevela()
    {
        var (sala, ana, bia, caio) = SalaComTres(SoEuNunca);
        var rodada = sala.Rodada!.Numero;
        sala.Responder(ana.Token, rodada, Sala.RespostaNunca);
        sala.Responder(bia.Token, rodada, Sala.RespostaNunca);

        sala.Sair(caio.Token);

        Assert.Equal(FaseDaSala.Revelada, sala.Fase);
    }
}
